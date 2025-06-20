module Ieducar
  class SendPostWorker
    class IeducarException < StandardError; end

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

    MAX_RETRY_COUNT = 10

    extend Ieducar::SendPostPerformer
    include Ieducar::SendPostPerformer
    include Sidekiq::Worker

    sidekiq_options retry: 2, dead: false

    sidekiq_retries_exhausted do |msg, ex|
      args = msg['args'][0..-3]

      performer(*args) do |posting, _, _|
        # Só NÃO envia para o Honeybadger se for erro de validação
        unless self.validation_error?(ex)
          Honeybadger.notify(ex)
        end

        if !posting.error_message?
          custom_error = "args: #{msg['args'].inspect}, error: #{ex.message}"

          posting.add_error!(
            I18n.t('ieducar_api.error.messages.post_error'),
            custom_error
          )
        end
      end
    end

    def perform(entity_id, posting_id, params, info, queue, retry_count)
      Honeybadger.context(posting_id: posting_id)

      performer(entity_id, posting_id, params, info) do |posting, params|
        params = params.with_indifferent_access
        information = info_message(info)

        begin
          response = IeducarResponseDecorator.new(api(posting).send_post(params))

          posting.add_warning!(response.full_error_message(information)) if response.any_error_message?
        rescue StandardError => error
          handle_error(error, information, posting, entity_id, posting_id, params, info, queue, retry_count)
        end
      end
    end

    private

    def handle_error(error, information, posting, entity_id, posting_id, params, info, queue, retry_count)
      # Erros que devem ser reenviados
      if should_retry_error?(error)
        log_retry_attempt(information, params, posting_id, entity_id)
        retry
      end

      # Se for erro de validação, apenas adiciona ao posting (não vai para Honeybadger)
      if self.class.validation_error?(error)
        posting.add_error!(
          I18n.t('ieducar_api.error.messages.post_error'),
          "#{information} Erro: #{error.message}"
        )
        return
      end

      # Tenta retry com delay para erros de rede
      return if delayed_retry(error, entity_id, posting_id, params, info, queue, retry_count)

      # Todos os outros erros vão para o Honeybadger
      raise StandardError, "#{information} Erro: #{error.message}"
    end

    def should_retry_error?(error)
      RETRY_ERRORS.any? { |retry_error| error.message.include?(retry_error) }
    end

    def self.validation_error?(error)
      VALIDATION_ERRORS.any? { |validation_error| error.message.include?(validation_error) }
    end

    def log_retry_attempt(information, params, posting_id, entity_id)
      Rails.logger.info(
        key: 'Ieducar::SendPostWorker#perform',
        info: information,
        params: params,
        posting_id: posting_id,
        entity_id: entity_id
      )
    end

    def delayed_retry(error, entity_id, posting_id, params, info, queue, retry_count)
      return false if retry_count == MAX_RETRY_COUNT
      return false unless error.is_a?(IeducarApi::Base::NetworkException)

      self.class.set(queue: queue).perform_in(
        ((retry_count + 1) * 2).seconds,
        entity_id,
        posting_id,
        params, info,
        queue,
        retry_count + 1
      )
    end

    def info_message(info)
      message = ''

      message += "Turma: #{classroom(info['classroom'])};<br>" if info.key?('classroom')
      message += "Aluno: #{student(info['student'])};<br>" if info.key?('student')
      message += "Componente curricular: #{discipline(info['discipline'])};<br>" if info.key?('discipline')

      message
    end

    def student(api_code)
      @students ||= {}
      @students[api_code] ||= Student.find_by(api_code: api_code).try(:name)
    end

    def discipline(api_code)
      @disciplines ||= {}
      @disciplines[api_code] ||= Discipline.find_by(api_code: api_code).try(:description)
    end

    def classroom(api_code)
      @classrooms ||= {}
      @classrooms[api_code] ||= Classroom.find_by(api_code: api_code).try(:description)
    end

    def data(params)
      params[:faltas] || params[:notas] || params[:pareceres]
    end

    def api(posting)
      case posting.post_type
      when ApiPostingTypes::NUMERICAL_EXAM
        IeducarApi::PostExams.new(posting.to_api)
      when ApiPostingTypes::CONCEPTUAL_EXAM
        IeducarApi::PostExams.new(posting.to_api)
      when ApiPostingTypes::DESCRIPTIVE_EXAM
        IeducarApi::PostDescriptiveExams.new(posting.to_api)
      when ApiPostingTypes::ABSENCE
        IeducarApi::PostAbsences.new(posting.to_api)
      when ApiPostingTypes::FINAL_RECOVERY
        IeducarApi::FinalRecoveries.new(posting.to_api)
      when ApiPostingTypes::SCHOOL_TERM_RECOVERY
        IeducarApi::PostRecoveries.new(posting.to_api)
      end
    end
  end
end
