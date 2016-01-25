require 'rails_helper'

RSpec.describe DisciplineLessonPlanPdf, type: :report do
  it "should be created" do
    entity_configuration = create(:entity_configuration)
    teacher_discipline_classroom = create(:teacher_discipline_classroom)
    lesson_plan = create(:lesson_plan, classroom: teacher_discipline_classroom.classroom)
    discipline_lesson_plan = create(:discipline_lesson_plan, discipline: teacher_discipline_classroom.discipline, lesson_plan: lesson_plan)

    subject = DisciplineLessonPlanPdf.build(
      entity_configuration,
      discipline_lesson_plan,
      teacher_discipline_classroom.teacher
    ).render

    expect(subject).to be_truthy
  end
end
