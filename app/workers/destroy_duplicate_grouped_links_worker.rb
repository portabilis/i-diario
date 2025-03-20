class DestroyDuplicatedGroupedLinksWorker
  include Sidekiq::Worker

  sidekiq_options unique: :until_and_while_executing, queue: :low

  def perform
    DestroyDuplicatedGroupedLinksService.call
  end
end
