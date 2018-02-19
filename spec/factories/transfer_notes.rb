FactoryGirl.define do
  factory :transfer_note do
    classroom
    discipline
    school_calendar_step
    student
    teacher
    transfer_date { Time.zone.today }

    after(:build) do |transfer_note|
      transfer_note.daily_note_students.build(build(:current_daily_note_student, note: 5).attributes)
    end
  end
end
