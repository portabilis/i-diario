module Ieducar
  class SendPostWorker
    extend Ieducar::SendPostPerformer
    include Ieducar::SendPostPerformer
    include Sidekiq::Worker

    sidekiq_options retry: 2, queue: :exam_posting_send

    sidekiq_retries_exhausted do |msg, ex|
      performer(*msg['args']) do |posting, _, _|
        custom_error = "args: #{msg['args'].inspect}, error: #{ex.message}"

        Honeybadger.notify(ex)

        posting.worker_batch.increment(params) do
          if !posting.error_message?
            posting.add_error!('Ocorreu um erro desconhecido.', custom_error)
          end

          posting.finish!
        end
      end
    end

    def perform(entity_id, posting_id, params)
      performer(entity_id, posting_id, params) do |posting, params|
        params = params.with_indifferent_access
        return if posting.error?

        begin
          api(posting).send_post(params)
        rescue Exception => e
          if e.message.match(/(Componente curricular de cÃ³digo).*(nÃ£o existe para a turma)/).present?
            posting.add_warning!("Componente curricular '#{discipline(params)}' não existe para a turma '#{classroom(params)}'")
          else
            raise e
          end
        end

        posting.worker_batch.increment(params) do
          posting.finish!
        end
      end
    end

    def discipline(params)
      discipline_id = params[:notas].first[1].first[1].first[0]

      @disciplines ||= {}
      @disciplines[discipline_id] ||= Discipline.find_by(api_code: discipline_id).description
    end

    def classroom(params)
      classroom_id = params[:notas].first[0]

      @classrooms ||= {}
      @classrooms[classroom_id] ||= Classroom.find_by(api_code: classroom_id).description
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
