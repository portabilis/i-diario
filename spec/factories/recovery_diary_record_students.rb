FactoryGirl.define do
  factory :recovery_diary_record_student do
    score 10.00

    association :recovery_diary_record, factory: :recovery_diary_record_with_students
    student
  end
end
