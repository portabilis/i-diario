module Ieducar
  class SendPostWorker
    extend Ieducar::SendPostPerformer
    include Ieducar::SendPostPerformer
    include Sidekiq::Worker

    sidekiq_options retry: 5, queue: :exam_posting_send

    sidekiq_retries_exhausted do |msg, ex|
      performer(*msg['args']) do |posting, _, _|
        custom_error = "args: #{msg['args'].inspect}, error: #{ex.message}"
        posting.mark_as_error!('Ocorreu um erro desconhecido.', custom_error)
      end
    end

    def perform(entity_id, posting_id, params, worker_batch_id)
      performer(entity_id, posting_id, params, worker_batch_id) do |posting, params, worker_batch_id|
        params = params.with_indifferent_access
        return if posting.error?

        begin
          IeducarApi::PostExams.new(posting.to_api).send_post(params)
        rescue Exception => e
          if e.message.match(/(Componente curricular de cÃ³digo).*(nÃ£o existe para a turma)/).present?
            posting.add_warning!("Componente curricular '#{discipline(params)}' não existe para a turma '#{classroom(params)}'")
          end

          raise e
        end

        WorkerBatch.increment(worker_batch_id, params) do
          if posting.warning_message.any?
            posting.mark_as_warning!
          else
            posting.mark_as_completed! 'Envio realizado com sucesso!'
          end
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
  end
end
