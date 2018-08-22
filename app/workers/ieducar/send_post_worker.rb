module Ieducar
  class SendPostWorker
    extend Ieducar::SendPostPerformer
    include Ieducar::SendPostPerformer
    include Sidekiq::Worker

    sidekiq_options retry: 2, queue: :exam_posting_send, dead: false

    sidekiq_retries_exhausted do |msg, ex|
      performer(*msg['args']) do |posting, _, _|
        Honeybadger.notify(ex)

        if !posting.error_message?
          custom_error = "args: #{msg['args'].inspect}, error: #{ex.message}"
          posting.add_error!('Ocorreu um erro desconhecido.', custom_error)
        end
      end
    end

    def perform(entity_id, posting_id, params)
      performer(entity_id, posting_id, params) do |posting, params|
        params = params.with_indifferent_access

        begin
          api(posting).send_post(params)
        rescue Exception => e
          error = "Aluno: #{student(params)};<br>
                   Componente curricular: #{discipline(params)};<br>
                   Turma: #{classroom(params)};<br>"

          if e.message.match(/(Componente curricular de cÃ³digo).*(nÃ£o existe para a turma)/).present?
            posting.add_warning!(error + "Erro: Componente curricular não existe para a turma.")
          elsif e.message.match(/Nota somente pode ser lançada após lançar notas nas etapas:/).present? ||
              e.message.match(/O secretário\/coordenador deve lançar as notas das etapas:/).present?
            posting.add_warning!(error + "Erro: #{e.message}")
          else
            raise e
          end
        end
      end
    end

    def student(params)
      student_id = notas(params).first[1].first[0]

      @students ||= {}
      @students[student_id] ||= Student.find_by(api_code: student_id).name
    end

    def discipline(params)
      discipline_id = notas(params).first[1].first[1].first[0]

      @disciplines ||= {}
      @disciplines[discipline_id] ||= Discipline.find_by(api_code: discipline_id).description
    end

    def classroom(params)
      classroom_id = notas(params).first[0]

      @classrooms ||= {}
      @classrooms[classroom_id] ||= Classroom.find_by(api_code: classroom_id).description
    end

    def notas(params)
      params[:notas] || params[:pareceres]
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
