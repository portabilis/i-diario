FactoryGirl.define do
  factory :student_enrollment do
    student

    status 3
    active { IeducarBooleanState::ACTIVE }

    trait :with_student_enrollment_classroom do
      after(:create) do |student_enrollment|
        create(
          :classroom,
          :with_student_enrollment_classroom,
          student_enrollment: student_enrollment
        )
      end
    end
  end
end
