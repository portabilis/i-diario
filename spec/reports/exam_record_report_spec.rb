require 'rails_helper'

RSpec.describe ExamRecordReport, type: :report do
  it "should be created" do
    entity_configuration = create(:entity_configuration)
    school_calendar = create(:school_calendar_with_one_step, year: 2016)
    avaliation = create(:avaliation, school_calendar: school_calendar, test_date: "04/01/2016")
    classroom = create(:classroom)
    unity = create(:unity)
    daily_note = create(:daily_note, avaliation: avaliation, classroom: classroom)
    student = create(:student)
    teacher = create(:teacher)
    test_setting = create(:test_setting)
    daily_note_student = create(:daily_note_student, daily_note: daily_note, student: student)

    daily_notes = DailyNote.all
    students = Student.where(id: student.id)

    subject = ExamRecordReport.build(
      entity_configuration,
      teacher,
      school_calendar.year,
      1,
      test_setting,
      daily_notes,
      students
    ).render

    expect(subject).to be_truthy
  end
end
