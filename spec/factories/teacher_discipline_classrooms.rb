FactoryGirl.define do
  factory :teacher_discipline_classroom do
    classroom
    teacher
    discipline

    classroom_api_code { classroom.api_code }
    teacher_api_code { teacher.api_code }
    discipline_api_code { discipline.api_code }
    sequence(:year) { |n| 2020 + n }
    allow_absence_by_discipline 0

    trait :current do
      year { Date.current.year }
    end
  end
end
