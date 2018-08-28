FactoryGirl.define do
  factory :school_term_recovery_diary_record do
    association :recovery_diary_record, factory: :recovery_diary_record_with_students
    school_calendar_step
    recorded_at { Date.current }

    after(:build) do |school_term_recovery_diary_record|
      school_term_recovery_diary_record.step_id = school_term_recovery_diary_record.school_calendar_step.id
    end

    factory :current_school_term_recovery_diary_record do
      association :recovery_diary_record, factory: :current_recovery_diary_record_with_students
    end
  end
end
