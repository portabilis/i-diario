class UniqueDailyFrequencyStudentsCreatorWorker
  include Sidekiq::Worker

  sidekiq_options unique: :until_and_while_executing, queue: :low

  def perform(entity_id, classroom_id, frequency_date, teacher_id)
    Entity.find(entity_id).using_connection do
      UniqueDailyFrequencyStudentsCreator.create!(classroom_id, frequency_date, teacher_id)
    end
  end
end
