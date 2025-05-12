class UserForStudentCreatorWorker
  include Sidekiq::Worker

  sidekiq_options unique: :until_and_while_executing, queue: :low

  def perform(entity_id, student_id)
    Entity.find(entity_id).using_connection do
      UserForStudentCreator.create!(student_id)
    end
  end
end
