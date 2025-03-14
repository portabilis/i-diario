class DestroyDuplicateGroupedLinksWorker
  include Sidekiq::Worker

  sidekiq_options unique: :until_and_while_executing, queue: :low

  def perform
    DeleteDuplicateGroupedLinksService.call
  end
end
