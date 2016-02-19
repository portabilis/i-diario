FactoryGirl.define do
  factory :avaliation_recovery_diary_record do
    association :recovery_diary_record, factory: :recovery_diary_record_with_students
    association :avaliation, factory: :avaliation
  end
end
