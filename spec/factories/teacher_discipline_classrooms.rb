FactoryGirl.define do
  factory :teacher_discipline_classroom do
    sequence(:year) { |n| 2020 + n }
    sequence(:teacher_api_code) { |n| n }
    sequence(:classroom_api_code) { |n| n }
    sequence(:discipline_api_code) { |n| n }

    teacher
    classroom
    discipline
  end
end