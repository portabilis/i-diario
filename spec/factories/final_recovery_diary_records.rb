FactoryGirl.define do
  factory :final_recovery_diary_record do
    association :recovery_diary_record, factory: [
      :recovery_diary_record,
      :with_teacher_discipline_classroom,
      :with_students
    ]
    association :school_calendar, factory: [:school_calendar, :with_one_step]
  end
end
