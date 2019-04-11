FactoryGirl.define do
  factory :discipline_lesson_plan do
    lesson_plan
    discipline

    after(:build) do |discipline_lesson_plan|
      teacher_discipline_classroom = create(
        :teacher_discipline_classroom,
        discipline: discipline_lesson_plan.discipline
      )

      discipline_lesson_plan.teacher_id = teacher_discipline_classroom.teacher.id
    end
  end
end
