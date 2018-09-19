FactoryGirl.define do
  factory :student_enrollment_classroom do
    api_code '1'
    student_enrollment
    classroom { build(:classroom_numeric_and_concept) }
    classroom_code '1'
    joined_at { "01/01/#{classroom.year}" }
    changed_at { Date.current.to_s }
    show_as_inactive_when_not_in_date false
  end
end
