# encoding: utf-8
module IeducarApi
  class Base
    class ApiError < Exception; end

    attr_accessor :url, :access_key, :secret_key, :unity_id

    def initialize(options = {})
      self.url = options.delete(:url)
      self.access_key = options.delete(:access_key)
      self.secret_key = options.delete(:secret_key)
      self.unity_id = options.delete(:unity_id)

      Honeybadger.context(
        url: url,
        unity_id: unity_id
      )

      raise ApiError.new("É necessário informar a url de acesso: url") if url.blank?
      raise ApiError.new("É necessário informar a chave de acesso: access_key") if access_key.blank?
      raise ApiError.new("É necessário informar a chave secreta: secret_key") if secret_key.blank?
      raise ApiError.new("É necessário informar o id da unidade: unity_id") if unity_id.blank?
    end

    def fetch(params = {})
      assign_staging_secret_keys if Rails.env.staging?

      request(RequestMethods::GET, params) do |endpoint, request_params|
        RestClient.get(endpoint, { params: request_params })
      end
    end

    def send_post(params = {})
      assign_staging_secret_keys unless Rails.env.production?

      request(RequestMethods::POST, params) do |endpoint, request_params|
        RestClient.post("#{endpoint}?#{request_params.to_param}", {})
      end
    end

    private

    def assign_staging_secret_keys
      self.access_key = '***REMOVED***'
      self.secret_key = '***REMOVED***'
    end

    def request(method, params = {})
      params.reverse_merge!(:oper => method)

      path = params.delete(:path)

      raise ApiError.new("É necessário informar o caminho de acesso: path") if path.blank?
      raise ApiError.new("É necessário informar o recurso de acesso: resource") if params[:resource].blank?

      endpoint = [url, path].join("/")

      request_params = {
        access_key: access_key,
        secret_key: secret_key,
        instituicao_id: unity_id
      }.reverse_merge(params)

      Rails.logger.info "#{method.upcase} #{endpoint}?#{request_params.to_query}"
      Sidekiq.logger.info "#{method.upcase} #{endpoint}?#{request_params.to_query}"

      Honeybadger.context(
        endpoint: endpoint,
        request_params: request_params,
        request_url: "#{endpoint}?#{request_params.to_query}"
      )

      begin
        result = yield(endpoint, request_params)
        result = JSON.parse(result)
      rescue SocketError, RestClient::ResourceNotFound
        raise ApiError.new("URL do i-Educar informada não é válida.")
      rescue => e
        raise ApiError.new(e.message)
      end

      if result["any_error_msg"]
        raise ApiError.new(result["msgs"].map { |r| r["msg"] }.join(", "))
      end

      result
    end
  end
end
