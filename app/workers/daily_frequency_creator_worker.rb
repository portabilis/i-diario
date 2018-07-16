class DailyFrequencyCreatorWorker
  include Sidekiq::Worker

  def perform(entity_id, daily_frequency_id)
    entity = Entity.find(entity_id)

    entity.using_connection do
      daily_frequency = DailyFrequency.find(daily_frequency_id)

      DailyFrequenciesCreator.new({
        unity_id: daily_frequency.unity_id,
        classroom_id: daily_frequency.classroom_id,
        frequency_date: daily_frequency.frequency_date,
        class_number: daily_frequency.class_number,
        discipline_id: daily_frequency.discipline_id,
        school_calendar: daily_frequency.school_calendar,
        origin: OriginTypes::WORKER
      }).find_or_create!
    end
  end
end
