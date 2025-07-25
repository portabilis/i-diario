class DeleteInvalidPresenceRecordWorker
  include Sidekiq::Worker

  sidekiq_options unique: :until_and_while_executing,
                  unique_args: ->(args) { args },
                  queue: :low,
                  on_conflict: { client: :log, server: :reject }

  def perform(entity_id, student_id, classroom_id)
    Entity.find(entity_id).using_connection do
      DeleteInvalidPresenceRecordService.new(student_id, classroom_id).run!
    end
  end
end
