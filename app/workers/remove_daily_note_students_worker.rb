class RemoveDailyNoteStudentsWorker
  include Sidekiq::Worker

  sidekiq_options unique: :until_and_while_executing,
                  unique_args: ->(args) { args },
                  queue: :low,
                  on_conflict: { client: :log, server: :reject }

  def perform(entity_id, joined_at, left_at, student_id, classroom_id)
    Entity.find(entity_id).using_connection do
      RemoveDailyNoteStudents.call(joined_at, left_at, student_id, classroom_id)
    end
  end
end
