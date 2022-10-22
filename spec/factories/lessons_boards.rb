FactoryGirl.define do
  factory :lessons_board do
    classrooms_grade
    period Periods::MATUTINAL
  end
end
