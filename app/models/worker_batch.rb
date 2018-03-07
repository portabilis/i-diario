class WorkerBatch < ActiveRecord::Base
  def set_total_workers!(total_workers)
    update_column(:total_workers, total_workers)
  end

  def done_worker!(worker)
    update_columns(
      done_workers: (done_workers + 1),
      completed_workers: (completed_workers << worker)
    )
  end

  def all_workers_finished?
    (total_workers == done_workers)
  end
end
