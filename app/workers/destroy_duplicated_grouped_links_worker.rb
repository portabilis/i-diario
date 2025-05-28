class DestroyDuplicatedGroupedLinksWorker
  include Sidekiq::Worker

  sidekiq_options unique: :until_and_while_executing, unique_args: ->(args) { args }, queue: :low

  def perform(entity_id)
    Entity.find(entity_id).using_connection do
      DestroyDuplicatedGroupedLinkService.call
    end
  end
end
