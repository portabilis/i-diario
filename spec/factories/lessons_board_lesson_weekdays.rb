FactoryGirl.define do
  factory :lessons_board_lesson_weekday do
    lessons_board_lesson
    teacher_discipline_classroom

    trait :with_allocations do
      after(:build) do |lessons_board_lesson_weekday, evaluator|
        teacher = create(:teacher)
        discipline = create(:discipline)
        teacher_discipline_classroom = evaluator.teacher_discipline_classroom ||
          create(:teacher_discipline_classroom, teacher: teacher, discipline: discipline)

        lessons_board_lesson_weekday.teacher_discipline_classroom = teacher_discipline_classroom
      end
    end
  end
end
