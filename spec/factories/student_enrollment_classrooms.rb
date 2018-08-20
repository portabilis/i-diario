FactoryGirl.define do
  factory :student_enrollment_classroom do
    api_code '1'
    student_enrollment
    classroom
    classroom_code '1'
    joined_at { Time.zone.today.to_s }
    changed_at { Time.zone.today.to_s }
  end
end
