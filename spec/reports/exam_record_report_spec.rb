require 'rails_helper'

RSpec.describe ExamRecordReport, type: :report do
  it "should be created" do
    entity_configuration = create(:entity_configuration)
    school_calendar = create(:school_calendar_with_one_step, year: 2016)

    school_calendar_step_two = create(:school_calendar_step,
      start_at: '01/07/2016',
      end_at: '20/12/2016',
      start_date_for_posting: '10/07/2016',
      end_date_for_posting: '30/12/2016',
      school_calendar: school_calendar)

    school_calendar.steps << school_calendar_step_two

    avaliation = create(:avaliation, school_calendar: school_calendar, test_date: "04/01/2016")
    classroom = create(:classroom)
    unity = create(:unity)
    daily_note = create(:daily_note, avaliation: avaliation)
    student = create(:student)
    student_enrollment = create(:student_enrollment, student: student)
    teacher = create(:teacher)
    test_setting = create(:test_setting)
    daily_note_student = create(:daily_note_student, daily_note: daily_note, student: student)

    daily_notes = DailyNote.all
    student_enrollments = StudentEnrollment.where(id: student.id)

    subject = ExamRecordReport.build(
      entity_configuration,
      teacher,
      school_calendar.year,
      school_calendar_step_two,
      test_setting,
      daily_notes,
      students,
      []
    ).render

    expect(subject).to be_truthy
  end
end
