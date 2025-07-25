module IeducarApi
  class Base
    class ApiError < RuntimeError; end
    class GenericError < RuntimeError; end
    class NetworkException < StandardError; end

    RETRY_NETWORK_ERRORS = ['Temporary failure in name resolution', '502 Bad Gateway'].freeze

    attr_accessor :url, :access_key, :secret_key, :unity_id, :full_synchronization

    def initialize(options = {}, full_synchronization = false)
      self.url = options.delete(:url)
      self.access_key = options.delete(:access_key)
      self.secret_key = options.delete(:secret_key)
      self.unity_id = options.delete(:unity_id)
      self.full_synchronization = full_synchronization

      Honeybadger.context(
        url: url,
        unity_id: unity_id
      )

      raise ApiError, 'É necessário informar a url de acesso: url' if url.blank?
      raise ApiError, 'É necessário informar a chave de acesso: access_key' if access_key.blank?
      raise ApiError, 'É necessário informar a chave secreta: secret_key' if secret_key.blank?
      raise ApiError, 'É necessário informar o id da unidade: unity_id' if unity_id.blank?
    end

    def fetch(params = {})
      ignore_modified = params.delete(:ignore_modified)
      params.reverse_merge!(modified: get_modified_date) unless full_synchronization || ignore_modified

      assign_staging_secret_keys if Rails.env.staging?

      request(RequestMethods::GET, params) do |endpoint, request_params|
        RestClient::Request.execute(
          method: :get,
          url: endpoint,
          read_timeout: 240,
          headers: {
            params: request_params
          }
        )
      end
    end

    def send_post(params = {})
      assign_staging_secret_keys unless Rails.env.production?

      request(RequestMethods::POST, params) do |endpoint, request_params, payload|
        RestClient.post("#{endpoint}?#{request_params.to_param}", payload, {})
      end
    end

    private

    def assign_staging_secret_keys
      self.access_key = Rails.application.secrets.staging_access_key
      self.secret_key = Rails.application.secrets.staging_secret_key
    end

    def request(method, params = {})
      params.reverse_merge!(oper: method)

      path = params.delete(:path)

      raise ApiError, 'É necessário informar o caminho de acesso: path' if path.blank?
      raise ApiError, 'É necessário informar o recurso de acesso: resource' if params[:resource].blank?

      endpoint = [url, path].join('/')

      request_params = {
        access_key: access_key,
        secret_key: secret_key,
        instituicao_id: unity_id
      }
      payload = {}
      method == RequestMethods::GET ? request_params.reverse_merge!(params) : payload = params

      if Rails.application.secrets.debug_ieducar_api
        Rails.logger.info "[DEBUG_IEDUCAR_API] Starting request to i-Educar API"
        Rails.logger.info "[DEBUG_IEDUCAR_API] Method: #{method.upcase}"
        Rails.logger.info "[DEBUG_IEDUCAR_API] Endpoint: #{endpoint}"
        Rails.logger.info "[DEBUG_IEDUCAR_API] Request params: #{request_params.to_json}"
        Rails.logger.info "[DEBUG_IEDUCAR_API] Payload: #{payload.to_json}" if payload.present?
        Rails.logger.info "[DEBUG_IEDUCAR_API] Full URL: #{endpoint}?#{request_params.to_query}"
        
        Sidekiq.logger.info "[DEBUG_IEDUCAR_API] #{method.upcase} #{endpoint}?#{request_params.to_query} payload: #{payload}"
      end

      Honeybadger.context(
        endpoint: endpoint,
        request_params: request_params,
        request_url: "#{endpoint}?#{request_params.to_query}",
        payload: params
      )

      begin
        result = if method == RequestMethods::GET
                   yield(endpoint, request_params)
                 else
                   request_params[:action] = params[:resource]
                   yield(endpoint, request_params, payload)
                 end
        if Rails.application.secrets.debug_ieducar_api
          Rails.logger.info "[DEBUG_IEDUCAR_API] Response received (raw): #{result.truncate(1000)}"
        end
        
        result = JSON.parse(result)
        
        if Rails.application.secrets.debug_ieducar_api
          Rails.logger.info "[DEBUG_IEDUCAR_API] Response parsed successfully"
          Rails.logger.info "[DEBUG_IEDUCAR_API] Response data: #{result.to_json.truncate(1000)}"
        end
      rescue SocketError, RestClient::ResourceNotFound, RestClient::BadGateway => error
        if Rails.application.secrets.debug_ieducar_api
          Rails.logger.error "[DEBUG_IEDUCAR_API] Network error occurred: #{error.class} - #{error.message}"
        end
        
        if RETRY_NETWORK_ERRORS.any? { |network_error| error.message.include?(network_error) }
          Honeybadger.notify(error)
          raise NetworkException, error.message
        end

        raise ApiError, 'URL do i-Educar informada não é válida.'
      rescue StandardError => error
        if Rails.application.secrets.debug_ieducar_api
          Rails.logger.error "[DEBUG_IEDUCAR_API] Error occurred: #{error.class} - #{error.message}"
          Rails.logger.error "[DEBUG_IEDUCAR_API] Backtrace: #{error.backtrace.first(5).join("\n")}"
        end
        
        Honeybadger.notify(error)

        raise GenericError, error.message
      end

      message = result['msgs'].map { |r| r['msg'] }.join(', ')

      response = IeducarResponseDecorator.new(result)
      raise_exception = response.any_error_message? && !response.known_error?
      
      if Rails.application.secrets.debug_ieducar_api
        Rails.logger.info "[DEBUG_IEDUCAR_API] API messages: #{message}" if message.present?
        Rails.logger.info "[DEBUG_IEDUCAR_API] Response has errors: #{response.any_error_message?}"
        Rails.logger.info "[DEBUG_IEDUCAR_API] Known error: #{response.known_error?}"
        Rails.logger.info "[DEBUG_IEDUCAR_API] Will raise exception: #{raise_exception}"
      end
      
      raise GenericError, message if raise_exception

      result
    end

    def get_modified_date
      @get_modified_date ||= begin
        last_sync = current_api_configuration.synchronized_at
        # Se a última sincronização foi nil, usa 7 dias atrás
        base_date = last_sync || 7.days.ago
        # A sincronização completa roda todo domingo, então a parcial vamos garantir
        # pegar todos os dados desde o último domingo para evitar perder dados
        # Encontra o último domingo (0 = domingo no Ruby)
        days_since_sunday = base_date.wday
        # Se estamos no domingo (wday = 0), vamos para o domingo anterior (7 dias atrás)
        # Se não, vamos para o domingo da semana passada
        days_to_subtract = days_since_sunday == 0 ? 7 : days_since_sunday
        base_date.beginning_of_day - days_to_subtract.days
      end
    end

    def current_api_configuration
      IeducarApiConfiguration.current
    end
  end
end
