FactoryGirl.define do
  factory :recovery_diary_record do
    recorded_at '2015-01-02'

    unity
    classroom
    discipline

    after(:build) do |recovery_diary_record|
      school_calendar = SchoolCalendar.find_by(year: 2015, unity_id: nil)
      school_calendar.destroy if school_calendar

      unless SchoolCalendar.find_by(year: 2015, unity_id: recovery_diary_record.unity_id)
        create(:school_calendar_with_one_step, year: 2015, unity_id: recovery_diary_record.unity_id)
      end
    end

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
