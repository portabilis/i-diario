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

      Rails.logger.info "#{method.upcase} #{endpoint}?#{request_params.to_query} payload: #{payload}"
      Sidekiq.logger.info "#{method.upcase} #{endpoint}?#{request_params.to_query} payload: #{payload}"

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
        result = JSON.parse(result)
      rescue SocketError, RestClient::ResourceNotFound, RestClient::BadGateway => error
        if RETRY_NETWORK_ERRORS.any? { |network_error| error.message.include?(network_error) }
          Honeybadger.notify(error)
          raise NetworkException, error.message
        end

        raise ApiError, 'URL do i-Educar informada não é válida.'
      rescue StandardError => error
        Honeybadger.notify(error)

        raise GenericError, error.message
      end

      message = result['msgs'].map { |r| r['msg'] }.join(', ')

      response = IeducarResponseDecorator.new(result)
      raise_exception = response.any_error_message? && !response.known_error?
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
        base_date.beginning_of_day - days_since_sunday.days
      end
    end

    def current_api_configuration
      IeducarApiConfiguration.current
    end
  end
end
