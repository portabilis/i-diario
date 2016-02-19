require 'rails_helper'

RSpec.describe DisciplineLessonPlanReport, type: :report do
  it "should be created" do
    entity_configuration = create(:entity_configuration)
    teacher_discipline_classroom = create(:teacher_discipline_classroom)
    lesson_plan = create(:lesson_plan, classroom: teacher_discipline_classroom.classroom)
    discipline_lesson_plan = create(:discipline_lesson_plan, discipline: teacher_discipline_classroom.discipline, lesson_plan: lesson_plan)

    discipline_lesson_plans = DisciplineLessonPlan.all

    subject = DisciplineLessonPlanReport.build(
      entity_configuration,
      "01/01/2016",
      "01/01/2016",
      discipline_lesson_plans,
      teacher_discipline_classroom.teacher
    ).render

    expect(subject).to be_truthy
  end

  it "should have correct identification section" do
    entity_configuration = create(:entity_configuration)
    teacher_discipline_classroom = create(:teacher_discipline_classroom)
    lesson_plan = create(:lesson_plan, classroom: teacher_discipline_classroom.classroom)
    discipline_lesson_plan = create(:discipline_lesson_plan, discipline: teacher_discipline_classroom.discipline, lesson_plan: lesson_plan)

    discipline_lesson_plans = DisciplineLessonPlan.all

    subject = DisciplineLessonPlanReport.build(
      entity_configuration,
      "01/01/2016",
      "01/01/2016",
      discipline_lesson_plans,
      teacher_discipline_classroom.teacher
    ).render

    subject = PDF::Inspector::Text.analyze(subject)

    expect(subject.strings).to include(discipline_lesson_plans.first.lesson_plan.unity.name)
  end
end
