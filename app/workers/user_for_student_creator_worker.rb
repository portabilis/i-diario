class UserForStudentCreatorWorker
  include Sidekiq::Worker

  def perform(entity_id)
    Entity.find(entity_id).using_connection do
      UserForStudentCreator.create!
    end
  end
end
