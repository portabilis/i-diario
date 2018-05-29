class WorkerBatch < ActiveRecord::Base
  def all_workers_finished?
    total_workers == done_workers
  end
end
