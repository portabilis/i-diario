class UniqueDailyFrequencyStudentsCreatorWorker
  include Sidekiq::Worker

  sidekiq_options unique: :until_and_while_executing, queue: :low

  def perform(entity_id, daily_frequency_id, teacher_id)
    Entity.find(entity_id).using_connection do
      UniqueDailyFrequencyStudentsCreator.create!(daily_frequency_id, teacher_id)
    end
  end
end
