class CreateEmptyConceptualExamValueWorker
  include Sidekiq::Worker

  sidekiq_options unique: :until_and_while_executing, queue: :low

  def perform(entity_id, classroom_id, teacher_id, grade_id, discipline_id)
    Entity.find(entity_id).using_connection do
      ConceptualExamValueCreator.create_empty_by(classroom_id, teacher_id, grade_id, discipline_id)
    end
  end
end
