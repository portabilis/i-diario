FactoryGirl.define do
  factory :student_enrollment_classroom do
    student_enrollment
    association :classrooms_grade, factory: [:classrooms_grade]

    sequence(:api_code, &:to_s)
    classroom_code { classrooms_grade.classroom.api_code }
    joined_at { "#{classrooms_grade.classroom.year}-01-01" }
    changed_at { Date.current.to_s }
    show_as_inactive_when_not_in_date false
    left_at ''
  end
end
