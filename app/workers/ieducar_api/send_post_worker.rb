module Ieducar
  class SendPostWorker
    include Sidekiq::Worker

    sidekiq_options retry: true, queue: :exam_posting_send

    def perform(entity_id, posting_id, params, worker_batch_id)
      entity = Entity.find(entity_id)

      entity.using_connection do
        posting = IeducarApiExamPosting.find(posting_id)
        worker_batch = WorkerBatch.find(worker_batch_id)

        IeducarApi::PostExams.new(posting.to_api).send_post(params)

        worker_batch.with_lock do
          worker_batch.update_attributes!(
            done_workers: (worker_batch.done_workers + 1),
            completed_workers: (worker_batch.completed_workers << params)
          )

          posting.mark_as_completed! 'Envio realizado com sucesso!' if worker_batch.all_workers_finished?
        end
      end
    end
  end
end
