FactoryGirl.define do
  factory :lessons_board_lesson do
    lessons_board
    lesson_number [1, 2, 3, 4, 5, 6].sample
  end
end
