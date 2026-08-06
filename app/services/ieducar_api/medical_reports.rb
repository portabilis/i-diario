module IeducarApi
  # Envia um laudo para o cadastro do aluno no i-Educar (POST /api/v2/aluno-laudo-upload).
  #
  # Não herda de IeducarApi::Base: a Base fala com a API legada (access_key/secret_key na query);
  # a API v2 do i-Educar autentica pelo header `token`, com o mesmo segredo compartilhado que o
  # i-Educar usa para chamar a API v2 do i-Diário (api_security_token, configurado nos dois lados).
  class MedicalReports
    UPLOAD_PATH = '/api/v2/aluno-laudo-upload'.freeze
    ALLOWED_EXTENSIONS = %w[jpg jpeg png pdf doc].freeze
    MAX_FILE_SIZE = 2.megabytes
    OPEN_TIMEOUT = 10
    READ_TIMEOUT = 60

    Result = Struct.new(:success, :message, :http_status) do
      def success?
        success
      end
    end

    def initialize(configuration = IeducarApiConfiguration.current)
      @configuration = configuration
    end

    def self.upload(student_api_code:, file:)
      new.upload(student_api_code: student_api_code, file: file)
    end

    def upload(student_api_code:, file:)
      validation_error = validation_message(file)
      return failure(validation_error, :unprocessable_entity) if validation_error
      return failure(t(:not_configured), :bad_gateway) unless configured?

      response = post_file(student_api_code, file)

      Result.new(true, message_from(response.body) || t(:success), :ok)
    rescue RestClient::Exceptions::Timeout, RestClient::ServerBrokeConnection,
           SocketError, SystemCallError => e
      log_and_notify(e, student_api_code, file)
      failure(t(:network_error), :bad_gateway)
    rescue RestClient::ExceptionWithResponse => e
      http_failure(e, student_api_code, file)
    end

    private

    attr_reader :configuration

    def post_file(student_api_code, file)
      RestClient::Request.execute(
        method: :post,
        url: "#{configuration.url}#{UPLOAD_PATH}",
        open_timeout: OPEN_TIMEOUT,
        read_timeout: READ_TIMEOUT,
        headers: { token: configuration.api_security_token },
        payload: { multipart: true, aluno_id: student_api_code, file: file }
      )
    end

    def validation_message(file)
      return t(:missing_file) if file.blank? || !file.respond_to?(:original_filename)
      return t(:invalid_type) unless allowed_extension?(file)

      t(:too_large) if file.size > MAX_FILE_SIZE
    end

    def allowed_extension?(file)
      extension = File.extname(file.original_filename.to_s).delete('.').downcase

      ALLOWED_EXTENSIONS.include?(extension)
    end

    def configured?
      configuration.url.present? && configuration.api_security_token.present?
    end

    def http_failure(error, student_api_code, file)
      status = error.response&.code
      remote_message = message_from(error.response&.body)

      case status
      when 422
        log_failure(error, student_api_code, file)
        failure(remote_message || t(:failed), :unprocessable_entity)
      when 401
        # Token divergente entre os dois sistemas.
        log_and_notify(error, student_api_code, file)
        failure(t(:unauthorized), :bad_gateway)
      when 404
        # i-Educar do município ainda sem o recurso de upload (deploy pendente).
        log_and_notify(error, student_api_code, file)
        failure(t(:endpoint_missing), :bad_gateway)
      else
        log_and_notify(error, student_api_code, file)
        failure(remote_message || t(:failed), :bad_gateway)
      end
    end

    def message_from(body)
      parsed = JSON.parse(body.to_s)

      parsed['message'].presence if parsed.is_a?(Hash)
    rescue JSON::ParserError
      nil
    end

    def failure(message, http_status)
      Result.new(false, message, http_status)
    end

    def log_failure(error, student_api_code, file)
      Rails.logger.error(
        "PEI laudo - falha no envio ao i-Educar (aluno #{student_api_code}, " \
        "arquivo #{file.try(:original_filename)}): #{error.class} - #{error.message}"
      )
    end

    def log_and_notify(error, student_api_code, file)
      log_failure(error, student_api_code, file)
      Honeybadger.notify(
        error,
        context: {
          student_api_code: student_api_code,
          filename: file.try(:original_filename),
          file_size: file.try(:size),
          url: "#{configuration.url}#{UPLOAD_PATH}"
        }
      )
    end

    def t(key)
      I18n.t("individualized_educational_plans.medical_report_upload.#{key}")
    end
  end
end
