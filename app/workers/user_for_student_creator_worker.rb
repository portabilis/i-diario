class UserForStudentCreatorWorker
  include Sidekiq::Worker

  sidekiq_options unique: :until_and_while_executing, queue: :low

  def perform(entity_id)
    Entity.find(entity_id).using_connection do
      UserForStudentCreator.create!
    end
  end
end
