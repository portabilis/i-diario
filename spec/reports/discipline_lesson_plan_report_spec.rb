require 'rails_helper'

RSpec.describe DisciplineLessonPlanReport, type: :report do
  it 'should be created' do
    entity_configuration = create(:entity_configuration)
    classroom = create(:classroom, :with_teacher_discipline_classroom, :with_classroom_semester_steps)
    teacher_discipline_classroom = classroom.teacher_discipline_classrooms.first
    lesson_plan = create(
      :lesson_plan,
      classroom: classroom,
      teacher_id: teacher_discipline_classroom.teacher.id
    )
    create(
      :discipline_lesson_plan,
      lesson_plan: lesson_plan,
      discipline: teacher_discipline_classroom.discipline,
      teacher_id: teacher_discipline_classroom.teacher.id
    )

    discipline_lesson_plans = DisciplineLessonPlan.all

    subject = DisciplineLessonPlanReport.build(
      entity_configuration,
      Date.current,
      Date.current,
      discipline_lesson_plans,
      teacher_discipline_classroom.teacher
    ).render

    expect(subject).to be_truthy
  end

  it 'should have correct identification section' do
    entity_configuration = create(:entity_configuration)
    classroom = create(:classroom, :with_teacher_discipline_classroom, :with_classroom_semester_steps)
    teacher_discipline_classroom = classroom.teacher_discipline_classrooms.first
    lesson_plan = create(
      :lesson_plan,
      classroom: classroom,
      teacher_id: teacher_discipline_classroom.teacher_id
    )
    create(
      :discipline_lesson_plan,
      lesson_plan: lesson_plan,
      discipline: teacher_discipline_classroom.discipline,
      teacher_id: teacher_discipline_classroom.teacher_id
    )

    discipline_lesson_plans = DisciplineLessonPlan.all

    subject = DisciplineLessonPlanReport.build(
      entity_configuration,
      Date.current,
      Date.current,
      discipline_lesson_plans,
      teacher_discipline_classroom.teacher
    ).render

    subject = PDF::Inspector::Text.analyze(subject)

    expect(subject.strings).to include(discipline_lesson_plans.first.lesson_plan.unity.name)
  end
end
