module IeducarApi
  class ErrorHandlerService
    # Exceções customizadas
    class PostRequestError < StandardError
      attr_reader :original_error, :information

      def initialize(error, information)
        @original_error = error
        @information = information
        super("#{information} Erro: #{error.message}")
      end
    end

    class RetryableError < PostRequestError; end

    class NetworkError < PostRequestError; end

    class ValidationError < PostRequestError; end

    # Erros que devem ser reenviados
    RETRY_ERRORS = [
      %(duplicate key value violates unique constraint "modules_nota_aluno_matricula_id_unique"),
      %(duplicate key value violates unique constraint "modules_parecer_aluno_matricula_id_unique"),
      %(duplicate key value violates unique constraint "falta_componente_curricular_pkey"),
      %(duplicate key value violates unique constraint "modules_falta_aluno_matricula_id_unique"),
      %(duplicate key value violates unique constraint "falta_geral_pkey"),
      %(duplicate key value violates unique constraint "nota_componente_curricular_pkey"),
      %(duplicate key value violates unique constraint "parecer_geral_pkey")
    ].freeze

    # Apenas erros de validação do usuário que NÃO devem ir para o Honeybadger
    VALIDATION_ERRORS = [
      'não é um valor numérico',
      'Exception: O parâmetro',
      'não pode estar vazio',
      'é obrigatório',
      'valor inválido',
      'formato inválido',
      'deve ser numérico',
      'URL do i-Educar informada não é válida'
    ].freeze

    def initialize(posting)
      @posting = posting
    end

    def handle(error, information)
      if should_retry_error?(error)
        raise RetryableError.new(error, information)
      elsif validation_error?(error)
        posting.add_error!(
          I18n.t('ieducar_api.error.messages.post_error'),
          "#{information} Erro: #{error.message}"
        )
      elsif network_error?(error)
        raise NetworkError.new(error, information)
      else
        raise StandardError, "#{information} Erro: #{error.message}"
      end
    end

    def self.validation_error?(error)
      VALIDATION_ERRORS.any? { |validation_error| error.message.include?(validation_error) }
    end

    private

    attr_reader :posting

    def should_retry_error?(error)
      RETRY_ERRORS.any? { |retry_error| error.message.include?(retry_error) }
    end

    def validation_error?(error)
      self.class.validation_error?(error)
    end

    def network_error?(error)
      error.is_a?(IeducarApi::Base::NetworkException)
    end
  end
end
