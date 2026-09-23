module IeducarApi
  # Base dos envios de lançamentos do aluno pelos endpoints da API v2 do i-Educar: um aluno por
  # requisição, payload achatado em JSON. As subclasses definem POST_PATH, LOG_PREFIX,
  # SUCCESS_MESSAGE, FIELDS (obrigatórios, na ordem do payload) e LOG_LABELS, e sobrescrevem
  # `payload_for` quando algum campo não é inteiro.
  #
  # Não herda de IeducarApi::Base: aquela fala com a API legada, que autentica por chaves na query
  # string e devolve erro de negócio dentro de um HTTP 200. Esta autentica pelo header `token` - o
  # `api_security_token` daqui é o `token_novo_educacao` de lá - e usa o status HTTP.
  #
  # A resposta é traduzida para o formato do IeducarResponseDecorator. As exceções continuam vindo
  # de Base porque o Ieducar::SendPostWorker decide o retry por Base::NetworkException.
  class V2Base
    SAVED_STATUS = 201
    OPEN_TIMEOUT = 10
    READ_TIMEOUT = 240
    RETRYABLE_STATUSES = [408, 429, 502, 503, 504].freeze
    # Erros de transporte: não têm resposta HTTP e valem nova tentativa.
    NETWORK_ERRORS = [
      RestClient::Exceptions::Timeout,
      RestClient::ServerBrokeConnection,
      RestClient::SSLCertificateNotVerified,
      OpenSSL::SSL::SSLError,
      SocketError,
      SystemCallError
    ].freeze
    # Identificação comum a todo endpoint, com o complemento das mensagens de erro.
    STUDENT_FIELDS = {
      turma_id: 'a turma',
      aluno_id: 'o aluno',
      etapa: 'a etapa'
    }.freeze
    STUDENT_LOG_LABELS = {
      turma_id: 'turma',
      aluno_id: 'aluno',
      etapa: 'etapa'
    }.freeze
    UNAUTHORIZED_MESSAGE = 'Token de segurança divergente entre o i-Diário e o i-Educar.'.freeze
    UNRECOGNIZED_RESPONSE_MESSAGE = 'O i-Educar devolveu uma resposta não reconhecida.'.freeze
    MAX_LOGGED_BODY = 500

    def initialize(configuration)
      raise Base::ApiError, 'É necessário informar a configuração da API do i-Educar' unless
        configuration.respond_to?(:api_security_token)

      @configuration = configuration
    end

    def send_post(params = {})
      params = (params || {}).with_indifferent_access

      validate!(params)

      handle_success(execute_post(params), params)
    # A ordem importa: no rest-client a exceção de timeout descende de ExceptionWithResponse, então
    # invertendo os dois rescues todo timeout cai no de baixo e perde o retry escalonado.
    rescue *NETWORK_ERRORS => error
      handle_network_error(error, params)
    rescue RestClient::ExceptionWithResponse => error
      handle_response_error(error, params)
    end

    protected

    def fields
      self.class::FIELDS
    end

    def payload_for(params)
      fields.each_with_object({}) do |(key, description), payload|
        payload[key] = integer_from(params, key, description)
      end
    end

    # `to_i` devolveria 0 para lixo, e 0 aqui é valor legítimo: zera as faltas do aluno na etapa.
    def integer_from(params, key, description)
      Integer(params[key].to_s, 10)
    rescue ArgumentError, TypeError
      raise Base::ApiError, "O valor informado para #{description} não é um número inteiro"
    end

    private

    attr_reader :configuration

    def validate!(params)
      fields.each do |key, description|
        raise Base::ApiError, "É necessário informar #{description}" if params[key].blank?
      end
      raise Base::ApiError, 'É necessário informar a url de acesso: url' if configuration.url.blank?

      return if request_token.present?

      raise Base::ApiError, 'É necessário informar o token de segurança do i-Diário'
    end

    def execute_post(params)
      payload = payload_for(params)

      log_debug("POST #{endpoint} payload: #{payload.to_json}")

      RestClient::Request.execute(
        method: :post,
        url: endpoint,
        open_timeout: OPEN_TIMEOUT,
        read_timeout: READ_TIMEOUT,
        payload: payload.to_json,
        headers: {
          token: request_token,
          content_type: :json,
          accept: :json
        }
      )
    end

    # Fora de produção, um dump restaurado traz a url e o token reais do cliente - um envio de
    # teste gravaria no i-Educar dele. Definir `staging_api_security_token` nos secrets do ambiente
    # restabelece o guard que a API legada tinha.
    def request_token
      return configuration.api_security_token if Rails.env.production?

      Rails.application.secrets.staging_api_security_token.presence ||
        configuration.api_security_token
    end

    def endpoint
      "#{configuration.url}#{self.class::POST_PATH}"
    end

    # Fora do 201, nenhuma resposta 2xx faz parte do contrato: pode ser um intermediário
    # respondendo no lugar do i-Educar, e tratá-la como gravação esconderia a falta não gravada.
    def handle_success(response, params)
      parsed = parse_body(response.body)

      return unrecognized_response!(response.code, response.body, params) if
        parsed.nil? || response.code != SAVED_STATUS

      message = message_from(parsed)

      message ||= self.class::SUCCESS_MESSAGE

      log_debug("Response: #{message}")

      success(message)
    end

    # Aluno sem matrícula ativa na turma - tipicamente o que deixou de frequentar. É desfecho
    # esperado e o professor não tem o que fazer, então fica só no log.
    def not_saved(message, params, status)
      log(:warn, 'matrícula recusada pelo i-Educar', params, status: status, detail: message)

      nothing_to_post
    end

    def handle_network_error(error, params)
      log(:error, 'falha de rede ao enviar', params, detail: "#{error.class} - #{error.message}")
      Honeybadger.notify(error, context: honeybadger_context(params))

      raise Base::NetworkException, error.message
    end

    def handle_response_error(error, params)
      status = error.http_code
      body = error.response&.body
      parsed = parse_body(body)
      message = message_from(parsed)

      case status
      when 422
        return unrecognized_response!(status, body, params) if message.blank?
        return not_saved(message, params, status) if registration_refused?(parsed)

        # Vira aviso, nos dois casos, para não derrubar o envio dos demais alunos da turma. Mas só
        # a recusa de validação é reportada: ela significa que nós enviamos algo fora do contrato.
        # A recusa de negócio - regra da turma que não permite o tipo de falta, componente fora da
        # turma - se repete a cada aluno enquanto a divergência existir, e notificá-la afogaria o
        # tracker.
        if validation_errors?(parsed)
          notify(error, params, status, message)
        else
          log(:warn, 'envio recusado pelo i-Educar', params, status: status, detail: message)
        end

        warning(message)
      when 401
        notify(error, params, status, message)

        raise Base::GenericError, UNAUTHORIZED_MESSAGE
      when *RETRYABLE_STATUSES
        log(:warn, 'recusa temporária do i-Educar', params, status: status, detail: message || error.message)

        raise Base::NetworkException, error.message
      else
        notify(error, params, status, message)

        # Preserva o texto do RestClient ("500 Internal Server Error") junto da mensagem remota: é
        # por eles que o worker classifica o erro e decide refazer a requisição sozinho.
        raise Base::GenericError, [error.message, message].reject(&:blank?).join(' - ')
      end
    end

    # O i-Educar valida a matrícula do aluno na turma junto com o formato do payload, e a recusa
    # chega como erro de validação só em `aluno_id`. O aluno sempre sai daqui como inteiro
    # (`payload_for`), então esse erro isolado é a matrícula, não o contrato.
    def registration_refused?(parsed)
      validation_errors?(parsed) && parsed['errors'].keys == ['aluno_id']
    end

    def unrecognized_response!(status, body, params)
      error = Base::GenericError.new("#{UNRECOGNIZED_RESPONSE_MESSAGE} (HTTP #{status})")

      log(:error, 'resposta não reconhecida', params, status: status, detail: truncate(body))
      Honeybadger.notify(
        error,
        context: honeybadger_context(params, status: status, remote_body: truncate(body))
      )

      raise error
    end

    def notify(error, params, status, message)
      log(:error, 'envio recusado pelo i-Educar', params, status: status, detail: message)
      Honeybadger.notify(
        error,
        context: honeybadger_context(params, status: status, remote_message: message)
      )
    end

    def parse_body(body)
      parsed = JSON.parse(body.to_s)

      parsed if parsed.is_a?(Hash)
    rescue JSON::ParserError
      nil
    end

    def message_from(parsed)
      return if parsed.nil?
      return parsed['errors'].values.flatten.join(' ') if validation_errors?(parsed)

      parsed['message'].presence
    end

    # A validação do Laravel devolve o detalhe em `errors`; as recusas de negócio trazem só
    # `message`. É o que separa "enviamos algo inválido" de "o i-Educar não aceita este caso".
    def validation_errors?(parsed)
      parsed.present? && parsed['errors'].is_a?(Hash) && parsed['errors'].present?
    end

    def success(message)
      {
        'msgs' => [{ 'msg' => message }],
        'any_error_msg' => false
      }
    end

    def nothing_to_post
      {
        'msgs' => [],
        'any_error_msg' => false
      }
    end

    def warning(message)
      {
        'msgs' => [],
        'any_error_msg' => true,
        'error' => { 'message' => message }
      }
    end

    def honeybadger_context(params, extra = {})
      {
        endpoint: endpoint,
        # Params crus: `payload_for` coage, e a coerção pode ser exatamente o que falhou.
        params: params.to_h
      }.merge(extra)
    end

    def log(level, description, params, status: nil, detail: nil)
      identification = self.class::LOG_LABELS.select { |key, _| params.key?(key) }
                                             .map { |key, label| "#{label}: #{params[key]}" }
                                             .join(', ')
      message = "#{self.class::LOG_PREFIX} #{description} - #{identification}"
      message += ", status: #{status}" if status.present?
      message += ", resposta: #{detail}" if detail.present?

      Rails.logger.public_send(level, message)
    end

    def truncate(body)
      body.to_s.truncate(MAX_LOGGED_BODY)
    end

    def log_debug(message)
      return unless Rails.application.secrets.debug_ieducar_api

      Rails.logger.info "[DEBUG_IEDUCAR_API] #{message}"
      Sidekiq.logger.info "[DEBUG_IEDUCAR_API] #{message}"
    end
  end
end
