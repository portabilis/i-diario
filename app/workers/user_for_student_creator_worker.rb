class UserForStudentCreatorWorker
  include Sidekiq::Worker

  def perform(entity_id, student_id)
    Entity.find(entity_id).using_connection do
      UserForStudentCreator.create!(student_id)
    end
  end
end
