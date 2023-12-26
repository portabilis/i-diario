require 'rails_helper'

RSpec.describe DisciplineLessonPlanPdf, type: :report do
  it 'should be created' do
    # entity_configuration = create(:entity_configuration)
    # classroom = create(:classroom, :with_teacher_discipline_classroom, :with_classroom_semester_steps)
    # teacher_discipline_classroom = classroom.teacher_discipline_classrooms.first
    # lesson_plan = create(
    #   :lesson_plan,
    #   classroom: classroom,
    #   teacher_id: teacher_discipline_classroom.teacher_id
    # )
    # discipline_lesson_plan = create(
    #   :discipline_lesson_plan,
    #   lesson_plan: lesson_plan,
    #   discipline: teacher_discipline_classroom.discipline,
    #   teacher_id: teacher_discipline_classroom.teacher_id
    # )
    #
    # subject = DisciplineLessonPlanPdf.build(
    #   entity_configuration,
    #   discipline_lesson_plan,
    #   teacher_discipline_classroom.teacher
    # ).render
    #
    # expect(subject).to be_truthy
  end
end
