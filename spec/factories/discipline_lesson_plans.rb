FactoryGirl.define do
  factory :discipline_lesson_plan do
    lesson_plan
    discipline

    transient do
      teacher nil
      classroom nil
    end

    trait :with_teacher_discipline_classroom do
      association :lesson_plan, factory: [:lesson_plan, :with_teacher_discipline_classroom]

      after(:build) do |discipline_lesson_plan, evaluator|
        teacher = Teacher.find(discipline_lesson_plan.teacher_id) if discipline_lesson_plan.teacher_id.present?
        teacher ||= evaluator.teacher || create(:teacher)
        discipline_lesson_plan.teacher_id ||= teacher.id
        classroom = evaluator.classroom || create(:classroom)
        discipline_lesson_plan.lesson_plan.teacher_id ||= teacher.id

        create(
          :teacher_discipline_classroom,
          discipline: discipline_lesson_plan.discipline,
          classroom: classroom,
          teacher: teacher
        )
      end
    end
  end
end
