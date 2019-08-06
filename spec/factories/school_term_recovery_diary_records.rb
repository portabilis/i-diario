FactoryGirl.define do
  factory :school_term_recovery_diary_record do
    association :recovery_diary_record, factory: :recovery_diary_record_with_students

    step_number 1

    factory :current_school_term_recovery_diary_record do
      association :recovery_diary_record, factory: :current_recovery_diary_record_with_students
    end

    after(:build) do |school_term_recovery_diary_record|
      recorded_at = school_term_recovery_diary_record.recovery_diary_record.recorded_at
      school_term_recovery_diary_record.recorded_at = recorded_at

      next if school_term_recovery_diary_record.step_id.present?

      school_calendar = create(:school_calendar, :current, :school_calendar_with_trimester_steps)
      step = school_calendar.step(school_term_recovery_diary_record.recorded_at)
      school_term_recovery_diary_record.step_id = step.id
      school_term_recovery_diary_record.step_number = step.step_number
    end
  end
end
