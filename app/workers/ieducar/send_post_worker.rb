module Ieducar
  class SendPostWorker
    extend Ieducar::SendPostPerformer
    include Ieducar::SendPostPerformer
    include Sidekiq::Worker

    sidekiq_options retry: 2, dead: false

    sidekiq_retries_exhausted do |msg, ex|
      performer(*msg['args']) do |posting, _, _|
        Honeybadger.notify(ex)

        if !posting.error_message?
          custom_error = "args: #{msg['args'].inspect}, error: #{ex.message}"

          posting.add_error!(
            I18n.t('ieducar_api.error.messages.post_error'),
            custom_error
          )
        end
      end
    end

    def perform(entity_id, posting_id, params, info)
      Honeybadger.context(posting_id: posting_id)

      performer(entity_id, posting_id, params, info) do |posting, params|
        params = params.with_indifferent_access
        information = info_message(info)

        begin
          response = IeducarResponseDecorator.new(api(posting).send_post(params))

          posting.add_warning!(response.full_error_message(information)) if response.any_error_message?
        rescue StandardError => error
          raise StandardError, "#{information} Erro: #{error.message}"
        end
      end
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
