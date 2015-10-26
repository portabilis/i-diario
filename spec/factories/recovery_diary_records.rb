FactoryGirl.define do
  factory :recovery_diary_record do
    recorded_at '2015-01-02'

    unity
    classroom
    discipline

    factory :recovery_diary_record_with_students do
      transient { students_count 5 }

      after(:build) do |recovery_diary_record, evaluator|
        evaluator.students_count.times do
          recovery_diary_record_student = build(:recovery_diary_record_student, recovery_diary_record: recovery_diary_record)
          recovery_diary_record.students << recovery_diary_record_student
        end
      end
    end
  end
end
