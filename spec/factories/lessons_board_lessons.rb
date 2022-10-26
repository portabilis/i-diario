FactoryGirl.define do
  factory :lessons_board_lesson do
    lessons_board

    trait :with_five_weekdays do
      after(:build) do |lesson_board_lesson|
        create(
          :lessons_board_lesson_weekday,
          lessons_board_lesson: lesson_board_lesson.lessons_board,
          weekday: :monday
        )
        create(
          :lessons_board_lesson_weekday,
          lessons_board_lesson: lesson_board_lesson.lessons_board,
          weekday: :tuesday
        )
        create(
          :lessons_board_lesson_weekday,
          lessons_board_lesson: lesson_board_lesson.lessons_board,
          weekday: :wednesday
        )
        create(
          :lessons_board_lesson_weekday,
          lessons_board_lesson: lesson_board_lesson.lessons_board,
          weekday: :thursday
        )
        create(
          :lessons_board_lesson_weekday,
          lessons_board_lesson: lesson_board_lesson.lessons_board,
          weekday: :friday
        )
      end
    end
  end
end
