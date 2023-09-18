class RemoveDailyNoteStudentsWorker
  include Sidekiq::Worker

  sidekiq_options unique: :until_and_while_executing, queue: :low

  def perform(entity_id, joined_at, left_at, student_id, classroom_id)
    Entity.find(entity_id).using_connection do
      RemoveDailyNoteStudents.call(joined_at, left_at, student_id, classroom_id)
    end
  end
end
