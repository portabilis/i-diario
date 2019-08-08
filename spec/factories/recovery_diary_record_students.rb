FactoryGirl.define do
  factory :recovery_diary_record_student do
    student
    association :recovery_diary_record, factory: :recovery_diary_record_with_students

    score { rand(1..10) }
  end
end
