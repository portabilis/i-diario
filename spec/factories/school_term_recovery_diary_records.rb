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
      recovery_diary_record = school_term_recovery_diary_record.recovery_diary_record
      step = evaluator.step

      unless step
        classroom = recovery_diary_record.classroom
        steps_fetcher = StepsFetcher.new(classroom)
        step = steps_fetcher.steps.first
      end

      school_term_recovery_diary_record.step_id ||= step.id
      school_term_recovery_diary_record.step_number = step.step_number

      school_term_recovery_diary_record.recorded_at = step.start_at + 1.day
      recovery_diary_record.recorded_at = step.start_at + 1.day

      recovery_diary_record.school_term_recovery_diary_record = school_term_recovery_diary_record if recovery_diary_record.present?
    end
  end
end
