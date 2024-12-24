FactoryGirl.define do
  factory :lessons_board do
    classrooms_grade
    period Periods::MATUTINAL

    trait :full_lessons_board do
      after(:create) do |lesson_board|
        create(:lessons_board_lesson, :with_five_weekdays, lessons_board: lesson_board, lesson_number: 1)
        create(:lessons_board_lesson, :with_five_weekdays, lessons_board: lesson_board, lesson_number: 2)
        create(:lessons_board_lesson, :with_five_weekdays, lessons_board: lesson_board, lesson_number: 3)
        create(:lessons_board_lesson, :with_five_weekdays, lessons_board: lesson_board, lesson_number: 4)
      end
    end
  end
end
