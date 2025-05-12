require 'rails_helper'

RSpec.describe AttendanceRecordReport, type: :report do
  it 'should be created' do
    skip 'needs to be refactored'
    entity_configuration = create(:entity_configuration)
    classroom = create(:classroom, :with_classroom_semester_steps)
    school_calendar = classroom.calendar.school_calendar

    create(
      :daily_frequency,
      frequency_date: "04/01/#{school_calendar.year}",
      classroom: classroom,
      school_calendar: school_calendar
    )
    create(:student)
    teacher = create(:teacher)

    daily_frequencies = DailyFrequency.all
    students = Student.all

    subject = AttendanceRecordReport.build(
      entity_configuration,
      teacher,
      school_calendar.year,
      '01/01/2016',
      '01/01/2016',
      daily_frequencies,
      students,
      school_calendar.events.by_date_between('01/01/2016', '01/01/2016').extra_school_without_frequency,
      school_calendar,
      false,
      {}
    ).render

    expect(subject).to be_truthy
  end
end
