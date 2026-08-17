module IeducarApi
  # Envia as faltas gerais de um aluno ao i-Educar (POST /api/v2/falta-geral).
  #
  # Não herda de IeducarApi::Base: aquela fala com a API legada, que autentica por chaves na query
  # string e devolve erro de negócio dentro de um HTTP 200. Esta autentica pelo header `token` — o
  # `api_security_token` daqui é o `token_novo_educacao` de lá — e usa o status HTTP.
  #
  # A resposta é traduzida para o formato do IeducarResponseDecorator. As exceções continuam vindo
  # de Base porque o Ieducar::SendPostWorker decide o retry por Base::NetworkException.
  class PostGeneralAbsences
    POST_PATH = '/api/v2/falta-geral'.freeze
    # O endpoint responde 202 quando gravou e 200 quando não havia matrícula elegível.
    SAVED_STATUS = 202
    OPEN_TIMEOUT = 10
    READ_TIMEOUT = 240
    NETWORK_ERROR_STATUSES = [502, 503, 504].freeze
    # Erros de transporte: não têm resposta HTTP e valem nova tentativa.
    NETWORK_ERRORS = [
      RestClient::Exceptions::Timeout,
      RestClient::ServerBrokeConnection,
      RestClient::SSLCertificateNotVerified,
      OpenSSL::SSL::SSLError,
      SocketError,
      SystemCallError
    ].freeze
    SUCCESS_MESSAGE = 'Faltas postadas com sucesso!'.freeze
    UNAUTHORIZED_MESSAGE = 'Token de segurança divergente entre o i-Diário e o i-Educar.'.freeze
    UNRECOGNIZED_RESPONSE_MESSAGE = 'O i-Educar devolveu uma resposta não reconhecida.'.freeze
    LOG_PREFIX = '[falta-geral]'.freeze
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

    private

    attr_reader :configuration

    def validate!(params)
      raise Base::ApiError, 'É necessário informar a etapa' if params[:etapa].blank?
      raise Base::ApiError, 'É necessário informar as faltas' if params[:faltas].blank?
      raise Base::ApiError, 'É necessário informar a turma' if params[:turma_id].blank?
      raise Base::ApiError, 'É necessário informar o aluno' if params[:aluno_id].blank?
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

    # Fora de produção, um dump restaurado traz a url e o token reais do cliente — um envio de
    # teste gravaria no i-Educar dele. Definir `staging_api_security_token` nos secrets do ambiente
    # restabelece o guard que a API legada tinha.
    def request_token
      return configuration.api_security_token if Rails.env.production?

      Rails.application.secrets.staging_api_security_token.presence ||
        configuration.api_security_token
    end

    def payload_for(params)
      {
        turma_id: integer_from(params, :turma_id, 'a turma'),
        aluno_id: integer_from(params, :aluno_id, 'o aluno'),
        etapa: integer_from(params, :etapa, 'a etapa'),
        faltas: integer_from(params, :faltas, 'as faltas')
      }
    end

    # `to_i` devolveria 0 para lixo, e 0 aqui é valor legítimo: zera as faltas do aluno na etapa.
    def integer_from(params, key, description)
      Integer(params[key].to_s, 10)
    rescue ArgumentError, TypeError
      raise Base::ApiError, "O valor informado para #{description} não é um número inteiro"
    end

    def endpoint
      "#{configuration.url}#{POST_PATH}"
    end

    def handle_success(response, params)
      parsed = parse_body(response.body)

      return unrecognized_response!('2xx', response.body, params) if parsed.nil?

      message = message_from(parsed)

      return not_saved(message, params, response.code) unless response.code == SAVED_STATUS

      log_debug("Response: #{message || SUCCESS_MESSAGE}")

      success(message || SUCCESS_MESSAGE)
    end

    # Matrícula fora das situações que o i-Educar aceita — tipicamente aluno que deixou de
    # frequentar. É desfecho esperado e o professor não tem o que fazer, então fica só no log.
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
      message = message_from(parse_body(body))

      case status
      when 404
        # Hoje 404 é a rota não existir — i-Educar do município sem o endpoint publicado — e
        # precisa falhar alto. Versões anteriores o usavam para matrícula inelegível, com mensagem
        # identificando o caso: daí o corpo ser considerado antes.
        return unrecognized_response!(status, body, params) if message.blank?

        not_saved(message, params, status)
      when 422
        # Recusa do i-Educar: regra da turma que não permite falta geral, ou payload fora do
        # contrato. Vira aviso para não derrubar o envio dos demais alunos, mas é reportado.
        return unrecognized_response!(status, body, params) if message.blank?

        notify(error, params, status, message)

        warning(message)
      when 401
        notify(error, params, status, message)

        raise Base::GenericError, UNAUTHORIZED_MESSAGE
      when *NETWORK_ERROR_STATUSES
        log(:warn, 'i-Educar indisponível', params, status: status, detail: error.message)

        raise Base::NetworkException, error.message
      else
        notify(error, params, status, message)

        # Preserva o texto do RestClient ("500 Internal Server Error") junto da mensagem remota: é
        # por eles que o worker classifica o erro e decide refazer a requisição sozinho.
        raise Base::GenericError, [error.message, message].reject(&:blank?).join(' - ')
      end
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
      return parsed['errors'].values.flatten.join(' ') if parsed['errors'].is_a?(Hash) && parsed['errors'].present?

      parsed['message'].presence
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

    def warning(message, code: nil)
      {
        'msgs' => [],
        'any_error_msg' => true,
        'error' => { 'code' => code, 'message' => message }
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
      message = "#{LOG_PREFIX} #{description} - turma: #{params[:turma_id]}, " \
                "aluno: #{params[:aluno_id]}, etapa: #{params[:etapa]}, faltas: #{params[:faltas]}"
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
