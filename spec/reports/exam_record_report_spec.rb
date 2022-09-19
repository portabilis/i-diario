require 'rails_helper'

RSpec.describe ExamRecordReport, type: :report do
  it 'should be created' do
    entity_configuration = create(:entity_configuration)
    discipline = create(:discipline)
    classroom = create(
      :classroom,
      :with_classroom_semester_steps,
      :with_teacher_discipline_classroom,
      :with_student_enrollment_classroom,
      discipline: discipline
    )
    school_calendar = classroom.calendar.school_calendar
    student = classroom.student_enrollment_classrooms.first.student_enrollment.student
    avaliation = create(
      :avaliation,
      school_calendar: school_calendar,
      classroom: classroom,
      discipline: discipline,
      teacher_id: classroom.teacher_discipline_classrooms.first.teacher_id,
      test_date: Date.current
    )
    daily_note = create(:daily_note, avaliation: avaliation)
    teacher = create(:teacher)
    test_setting = create(:test_setting)
    create(:daily_note_student, daily_note: daily_note, student: student)

    daily_notes = DailyNote.all
    students = StudentEnrollment.all

    subject = ExamRecordReport.build(
      entity_configuration,
      teacher,
      school_calendar.year,
      classroom.calendar.classroom_steps.last,
      test_setting,
      daily_notes,
      students,
      [],
      [],
      [],
      false,
    ).render

    expect(subject).to be_truthy
  end
end
