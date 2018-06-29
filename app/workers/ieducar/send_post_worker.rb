module Ieducar
  class SendPostWorker
    extend SendPostPerformer
    include SendPostPerformer
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
        return if posting.error?

        IeducarApi::PostExams.new(posting.to_api).send_post(params.with_indifferent_access)

        WorkerBatch.increment(worker_batch_id, params) do
          posting.mark_as_completed! 'Envio realizado com sucesso!'
        end
      end
    end
  end
end
