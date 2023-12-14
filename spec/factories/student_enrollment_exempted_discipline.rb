FactoryGirl.define do
  factory :student_enrollment_exempted_discipline do
    association :student_enrollment, factory: [:student_enrollment]
    association :discipline, factory: [:discipline]

    steps 1
  end
end
