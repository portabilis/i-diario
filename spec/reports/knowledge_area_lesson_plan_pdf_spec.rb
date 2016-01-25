require 'rails_helper'

RSpec.describe KnowledgeAreaLessonPlanPdf, type: :report do
  it "should be created" do
    entity_configuration = create(:entity_configuration)
    teacher_discipline_classroom = create(:teacher_discipline_classroom)
    lesson_plan = create(:lesson_plan, classroom: teacher_discipline_classroom.classroom)
    knowledge_area = create(:knowledge_area)
    knowledge_area_lesson_plan = create(:knowledge_area_lesson_plan, lesson_plan: lesson_plan, knowledge_area_ids: knowledge_area.id)

    subject = KnowledgeAreaLessonPlanPdf.build(
      entity_configuration,
      knowledge_area_lesson_plan,
      teacher_discipline_classroom.teacher
    ).render

    expect(subject).to be_truthy
  end
end
