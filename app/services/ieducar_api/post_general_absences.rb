module IeducarApi
  # Envia as faltas gerais de um aluno ao i-Educar (POST /api/v2/falta-geral).
  #
  # Não herda de IeducarApi::Base: a Base fala com a API legada, que autentica por
  # access_key/secret_key na query string, recebe as faltas em um hash aninhado
  # (turma => aluno => valor) e responde sempre em HTTP 200 no formato
  # { msgs: [...], any_error_msg: bool, error: {...} }.
  #
  # A API v2 autentica pelo header `token` — o mesmo segredo compartilhado entre os dois sistemas
  # (api_security_token aqui, token_novo_educacao no i-Educar) —, recebe um aluno por requisição
  # em payload achatado e sinaliza o resultado pelo status HTTP, com o texto em { message: "..." }.
  #
  # Para não espalhar o contrato novo pelo resto da aplicação, a resposta HTTP é traduzida aqui
  # para o formato que IeducarResponseDecorator já entende.
  class PostGeneralAbsences
    POST_PATH = '/api/v2/falta-geral'.freeze
    OPEN_TIMEOUT = 10
    READ_TIMEOUT = 240
    # Status que indicam indisponibilidade momentânea do i-Educar e valem uma nova tentativa.
    NETWORK_ERROR_STATUSES = [502, 503, 504].freeze
    SUCCESS_MESSAGE = 'Faltas postadas com sucesso!'.freeze
    REGISTRATION_NOT_FOUND_MESSAGE = 'Matrícula não encontrada para o aluno e turma informados.'.freeze
    INVALID_DATA_MESSAGE = 'O i-Educar recusou os dados enviados.'.freeze
    UNAUTHORIZED_MESSAGE = 'Token de segurança divergente entre o i-Diário e o i-Educar.'.freeze

    def initialize(configuration = IeducarApiConfiguration.current)
      @configuration = configuration
    end

    def send_post(params = {})
      params = params.with_indifferent_access

      validate!(params)

      response = execute_post(params)

      success(message_from(response.body) || SUCCESS_MESSAGE)
    rescue RestClient::ExceptionWithResponse => error
      handle_response_error(error, params)
    rescue RestClient::Exceptions::Timeout, RestClient::ServerBrokeConnection, SocketError,
           SystemCallError => error
      log_debug("Network error occurred: #{error.class} - #{error.message}")
      Honeybadger.notify(error, context: honeybadger_context(params))

      raise Base::NetworkException, error.message
    end

    private

    attr_reader :configuration

    def validate!(params)
      raise Base::ApiError, 'É necessário informar a etapa' if params[:etapa].blank?
      raise Base::ApiError, 'É necessário informar as faltas' if params[:faltas].blank?
      raise Base::ApiError, 'É necessário informar a turma' if params[:turma_id].blank?
      raise Base::ApiError, 'É necessário informar o aluno' if params[:aluno_id].blank?
      raise Base::ApiError, 'É necessário informar a url de acesso: url' if configuration.url.blank?

      return if configuration.api_security_token.present?

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
          token: configuration.api_security_token,
          content_type: :json,
          accept: :json
        }
      )
    end

    def payload_for(params)
      {
        turma_id: params[:turma_id].to_i,
        aluno_id: params[:aluno_id].to_i,
        etapa: params[:etapa].to_i,
        faltas: params[:faltas].to_i
      }
    end

    def endpoint
      "#{configuration.url}#{POST_PATH}"
    end

    def handle_response_error(error, params)
      status = error.response&.code
      message = message_from(error.response&.body)

      case status
      when 404, 422
        # 404: o aluno não tem matrícula ativa na turma informada. 422: o i-Educar recusou o
        # payload. Nenhum dos dois se resolve com nova tentativa, então viram aviso no
        # acompanhamento do envio em vez de derrubar a postagem inteira.
        warning(message || default_message_for(status))
      when 401
        Honeybadger.notify(error, context: honeybadger_context(params))

        raise Base::GenericError, UNAUTHORIZED_MESSAGE
      when *NETWORK_ERROR_STATUSES
        raise Base::NetworkException, error.message
      else
        Honeybadger.notify(error, context: honeybadger_context(params))

        raise Base::GenericError, message.presence || error.message
      end
    end

    def default_message_for(status)
      status == 404 ? REGISTRATION_NOT_FOUND_MESSAGE : INVALID_DATA_MESSAGE
    end

    def message_from(body)
      parsed = JSON.parse(body.to_s)

      return unless parsed.is_a?(Hash)
      return parsed['errors'].values.flatten.join(' ') if parsed['errors'].is_a?(Hash) && parsed['errors'].present?

      parsed['message'].presence
    rescue JSON::ParserError
      nil
    end

    def success(message)
      log_debug("Response: #{message}")

      {
        'msgs' => [{ 'msg' => message }],
        'any_error_msg' => false
      }
    end

    def warning(message)
      log_debug("Response with warning: #{message}")

      {
        'msgs' => [],
        'any_error_msg' => true,
        'error' => { 'message' => message }
      }
    end

    def honeybadger_context(params)
      {
        endpoint: endpoint,
        payload: payload_for(params)
      }
    end

    def log_debug(message)
      return unless Rails.application.secrets.debug_ieducar_api

      Rails.logger.info "[DEBUG_IEDUCAR_API] #{message}"
      Sidekiq.logger.info "[DEBUG_IEDUCAR_API] #{message}"
    end
  end
end
