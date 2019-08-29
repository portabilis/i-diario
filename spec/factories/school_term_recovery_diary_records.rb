FactoryGirl.define do
  factory :school_term_recovery_diary_record do
    association :recovery_diary_record, factory: [
      :recovery_diary_record,
      :with_classroom_semester_steps,
      :with_teacher_discipline_classroom,
      :with_students
    ]

    step_number 1

    transient do
      step nil
    end

    after(:build) do |school_term_recovery_diary_record, evaluator|
      recorded_at = school_term_recovery_diary_record.recovery_diary_record.recorded_at
      school_term_recovery_diary_record.recorded_at = recorded_at
      step = evaluator.step || school_term_recovery_diary_record.step
      school_term_recovery_diary_record.step_id ||= step.id
      school_term_recovery_diary_record.step_number = step.step_number
    end
  end
end
