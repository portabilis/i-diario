FactoryGirl.define do
  factory :final_recovery_diary_record do
    association :recovery_diary_record, factory: :recovery_diary_record_with_students
    association :school_calendar, factory: :school_calendar_with_one_step
  end
end
