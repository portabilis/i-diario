FactoryGirl.define do
  factory :student_enrollment_dependence do
    association :student_enrollment, factory: [:student_enrollment]
    association :discipline, factory: [:discipline]

    student_enrollment_code { student_enrollment.api_code }
    discipline_code { discipline.api_code }
  end
end