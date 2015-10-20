FactoryGirl.define do
  factory :school_term_recovery_diary_record do
    association :recovery_diary_record, factory: :recovery_diary_record_with_students
    school_calendar_step
  end
end
