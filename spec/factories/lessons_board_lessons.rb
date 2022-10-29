FactoryGirl.define do
  factory :lessons_board_lesson do
    lessons_board

    trait :with_five_weekdays do
      after(:create) do |lesson_board_lesson|
        create(
          :lessons_board_lesson_weekday,
          lessons_board_lesson: lesson_board_lesson,
          weekday: :monday
        )
        create(
          :lessons_board_lesson_weekday,
          lessons_board_lesson: lesson_board_lesson,
          weekday: :tuesday
        )
        create(
          :lessons_board_lesson_weekday,
          lessons_board_lesson: lesson_board_lesson,
          weekday: :wednesday
        )
        create(
          :lessons_board_lesson_weekday,
          lessons_board_lesson: lesson_board_lesson,
          weekday: :thursday
        )
        create(
          :lessons_board_lesson_weekday,
          lessons_board_lesson: lesson_board_lesson,
          weekday: :friday
        )
      end
    end
  end
end
