FactoryGirl.define do
  factory :teacher_discipline_classroom do
    sequence(:year) { |n| 2020 + n }
    sequence(:teacher_api_code) { |n| n.to_s }
    sequence(:classroom_api_code) { |n| n.to_s }
    sequence(:discipline_api_code) { |n| n.to_s }

    allow_absence_by_discipline 0

    teacher
    classroom
    discipline
  end
end
