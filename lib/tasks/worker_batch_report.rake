require 'csv'

desc "Generate a CSV file with the worker batches. Ex: rake worker_batch_report[2025,1,1]"
task :worker_batch_report, [:year, :month, :day] => :environment do |t, args|
  args.with_defaults(year: '2025', month: '1', day: '1')
  start_date = Date.new(args[:year].to_i, args[:month].to_i, args[:day].to_i)

  CSV.open("worker_batches.csv", "w") do |csv|
    csv << ["Entity", "main_job_class", "WorkerBatch ID", "Started At", "Ended At", "Done Workers", "Total Workers", "Status"]

    Entity.active.each do |entity|
      entity.using_connection do
        WorkerBatch.where(
          created_at: start_date..Date.current,
          status: ApiSynchronizationStatus::COMPLETED
        ).order(created_at: :desc).find_each do |batch|
          csv << [
            entity.name,
            batch.main_job_class,
            batch.id,
            batch.started_at,
            batch.ended_at,
            batch.done_workers,
            batch.total_workers,
            batch.status
          ]
        end
      end
    end
  end
end