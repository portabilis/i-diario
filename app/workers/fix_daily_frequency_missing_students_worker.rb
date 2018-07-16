class FixDailyFrequencyMissingStudentsWorker
  include Sidekiq::Worker

  def perform(entity_id = nil)
    entities = Entity.where(id: entity_id) if entity_id.present?
    entities ||= Entity.all

    entities.each do |entity|
      entity.using_connection do
        frequencies = DailyFrequency.by_frequency_date_between('2018-01-01'.to_date, '2018-12-31'.to_date)

        frequencies.each do |daily_frequency|
          DailyFrequencyCreatorWorker.perform_async(entity.id, daily_frequency.id)
        end
      end
    end
  end
end
