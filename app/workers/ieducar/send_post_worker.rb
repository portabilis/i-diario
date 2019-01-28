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
          posting.add_error!(
            I18n.t('ieducar_api.error.messages.post_error'),
            ex.message
          )
        end
      end
    end

    def perform(entity_id, posting_id, params, info)
      Honeybadger.context(posting_id: posting_id)

      performer(entity_id, posting_id, params, info) do |posting, params|
        params = params.with_indifferent_access

        begin
          api(posting).send_post(params)
        rescue StandardError => error
          information = info_message(info)

          if error.message.match(/(Componente curricular de cÃ³digo).*(nÃ£o existe para a turma)/).present?
            posting.add_warning!("#{information} Erro: Componente curricular não existe para a turma.")
          elsif error.message.match(/Nota somente pode ser lançada após lançar notas nas etapas:/).present? ||
                error.message.match(/O secretário\/coordenador deve lançar as notas das etapas:/).present?
            posting.add_warning!("#{information} Erro: #{error.message}")
          else
            raise StandardError, "#{information} Erro: #{error.message}"
          end
        end
      end
    end

    def info_message(info)
      message = ''

      message += "Turma: #{info['classroom']} \n" if info.key?('classroom')
      message += "Aluno: #{info['student']} \n" if info.key?('student')
      message += "Componente curricular: #{info['discipline']} \n" if info.key?('discipline')

      message
    end

    def student(params)
      student_id = data(params).first[1].first[0]

      @students ||= {}
      @students[student_id] ||= Student.find_by(api_code: student_id).try(:name)
    end

    def discipline(params)
      discipline_id = data(params).first[1].first[1].first[0]

      @disciplines ||= {}
      @disciplines[discipline_id] ||= Discipline.find_by(api_code: discipline_id).try(:description)
    end

    def classroom(params)
      classroom_id = data(params).first[0]

      @classrooms ||= {}
      @classrooms[classroom_id] ||= Classroom.find_by(api_code: classroom_id).try(:description)
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
