class FixDailyFrequencyMissingStudentsWorker
  include Sidekiq::Worker

  def perform(entity_id = nil)
    entities = Entity.where(id: entity_id) if entity_id.present?
    entities ||= Entity.active

    entities.each do |entity|
      entity.using_connection do
        frequencies = DailyFrequency.by_frequency_date_between('2018-01-01'.to_date, '2018-07-17'.to_date)

        worker_batch = WorkerBatch.create!(
          main_job_class: 'FixDailyFrequencyMissingStudentsWorker',
          main_job_id: jid,
          total_workers: frequencies.count
        )

        frequencies.each do |daily_frequency|
          DailyFrequencyCreatorWorker.perform_async(entity.id, daily_frequency.id, worker_batch.id)
        end
      end
    end
  end
end
