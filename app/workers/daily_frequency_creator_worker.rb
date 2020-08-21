class DailyFrequencyCreatorWorker
  include Sidekiq::Worker

  sidekiq_options queue: :low

  def perform(entity_id, daily_frequency_id, worker_batch_id)
    entity = Entity.find(entity_id)

    entity.using_connection do
      daily_frequency = DailyFrequency.find(daily_frequency_id)

      DailyFrequenciesCreator.new(
        unity_id: daily_frequency.unity_id,
        classroom_id: daily_frequency.classroom_id,
        frequency_date: daily_frequency.frequency_date,
        class_numbers: [daily_frequency.class_number],
        discipline_id: daily_frequency.discipline_id,
        school_calendar: daily_frequency.school_calendar,
        origin: OriginTypes::WORKER
      ).find_or_create!

      worker_batch = WorkerBatch.find(worker_batch_id)
      worker_batch.increment
    end
  end
end
