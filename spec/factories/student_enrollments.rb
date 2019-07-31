FactoryGirl.define do
  factory :student_enrollment do
    student

    status 3
    active { IeducarBooleanState::ACTIVE }
  end
end
