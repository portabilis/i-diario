class CreateEmptyConceptualExamValueWorker
  include Sidekiq::Worker

  sidekiq_options unique: :until_and_while_executing, queue: :low
  CreateEmptyConceptualExamValueWorker.perform_in(
    1.second,
    entity_id,
    classroom_id,
    teacher_id,
    grades_in_disciplines
  )
end
  def perform(entity_id, classroom_id, teacher_id, grades_in_disciplines)
    Entity.find(entity_id).using_connection do
      ConceptualExamValueCreator.create_empty_by(classroom_id, teacher_id, grades_in_disciplines)
    end
  end
end
