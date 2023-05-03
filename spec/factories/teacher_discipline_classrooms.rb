FactoryGirl.define do
  factory :teacher_discipline_classroom do
    classroom
    teacher
    discipline
    grade

    year { Date.current.year }
    classroom_api_code { classroom.api_code }
    teacher_api_code { teacher.api_code }
    discipline_api_code { discipline.api_code }
    allow_absence_by_discipline 1

    trait :with_classroom_semester_steps do
      association :classroom, factory: [:classroom, :with_classroom_semester_steps]
    end
  end
end
