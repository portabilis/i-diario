FactoryGirl.define do
  factory :student_enrollment_classroom do
    student_enrollment
    association :classroom, factory: [:classroom, :score_type_numeric_and_concept]

    sequence(:api_code, &:to_s)
    classroom_code { classroom.api_code }
    joined_at { "01/01/#{classroom.year}" }
    changed_at { Date.current.to_s }
    show_as_inactive_when_not_in_date false
  end
end
