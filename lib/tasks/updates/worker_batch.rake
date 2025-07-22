namespace :updates do
  namespace :worker_batch do
    desc "Fixes nil stateable on WorkerBatch based in the main_job_class and main_job_id"
    task fix_nil_stateable: :environment do
      Entity.find_each do |entity|
        entity.using_connection do
          WorkerBatch.where(stateable: nil, main_job_class: 'IeducarSynchronizerWorker').update_all(
            "stateable_type = 'IeducarApiSynchronization', stateable_id = (SELECT id FROM ieducar_api_synchronizations WHERE job_id = worker_batches.main_job_id)"
          )
        end
      end
    end
  end
end