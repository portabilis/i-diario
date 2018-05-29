class FixDailyFrequencyMissingStudentsWorker
  include Sidekiq::Worker

  def perform(entity_id)
    entity = Entity.find(entity_id)

    entity.using_connection do

      frequencies = DailyFrequency.by_frequency_date_between('2018-01-01'.to_date, '2018-12-31'.to_date)

      frequencies.each do |daily_frequency|
        DailyFrequenciesCreator.new({
          unity_id: daily_frequency.unity_id,
          classroom_id: daily_frequency.classroom_id,
          frequency_date: daily_frequency.frequency_date,
          class_number: daily_frequency.class_number,
          discipline_id: daily_frequency.discipline_id,
          school_calendar: daily_frequency.school_calendar
        }).find_or_create!
      end

    end
  end
end
