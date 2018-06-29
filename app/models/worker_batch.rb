class WorkerBatch < ActiveRecord::Base
  def all_workers_finished?
    total_workers == done_workers
  end

  def self.increment(worker_batch_id, done_info)
    worker_batch = WorkerBatch.find(worker_batch_id)
    worker_batch.with_lock do
      worker_batch.update_attributes!(
        done_workers: (worker_batch.done_workers + 1),
        completed_workers: (worker_batch.completed_workers << done_info)
      )

      if block_given? && worker_batch.all_workers_finished?
        yield
      end
    end
  end

  def self.finish!(worker_batch_id, done_info)
    worker_batch = WorkerBatch.find(worker_batch_id)
    worker_batch.with_lock do
      if block_given? && worker_batch.all_workers_finished?
        yield
      end
    end
  end
end
