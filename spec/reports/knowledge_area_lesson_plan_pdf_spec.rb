require 'rails_helper'

RSpec.describe KnowledgeAreaLessonPlanPdf, type: :report do
  it 'should be created' do
    entity_configuration = create(:entity_configuration)
    discipline = create(:discipline)
    classroom = create(
      :classroom,
      :with_teacher_discipline_classroom,
      :with_classroom_semester_steps,
      discipline: discipline
    )
    teacher_discipline_classroom = classroom.teacher_discipline_classrooms.first
    lesson_plan = create(
      :lesson_plan,
      classroom: classroom,
      teacher_id: teacher_discipline_classroom.teacher.id
    )
    knowledge_area_lesson_plan = create(
      :knowledge_area_lesson_plan,
      lesson_plan: lesson_plan,
      knowledge_area_ids: discipline.knowledge_area.id,
      teacher_id: teacher_discipline_classroom.teacher.id
    )

    subject = KnowledgeAreaLessonPlanPdf.build(
      entity_configuration,
      knowledge_area_lesson_plan,
      teacher_discipline_classroom.teacher
    ).render

    expect(subject).to be_truthy
  end
end
