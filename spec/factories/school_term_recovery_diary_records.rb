FactoryGirl.define do
  factory :school_term_recovery_diary_record do
    association :recovery_diary_record, factory: :recovery_diary_record_with_students

    after(:build) do |school_term_recovery_diary_record|
      school_term_recovery_diary_record.recorded_at = school_term_recovery_diary_record.recovery_diary_record.recorded_at

      if school_term_recovery_diary_record.step_id.blank?
        school_calendar = create(:school_calendar, :current, :school_calendar_with_trimester_steps)
        school_term_recovery_diary_record.step_id = school_calendar.step(school_term_recovery_diary_record.recorded_at).id
      end
    end

    factory :current_school_term_recovery_diary_record do
      association :recovery_diary_record, factory: :current_recovery_diary_record_with_students
    end
  end
end
