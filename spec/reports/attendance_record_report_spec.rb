require 'rails_helper'

RSpec.describe AttendanceRecordReport, type: :report do
  it "should be created" do
    entity_configuration = create(:entity_configuration)
    school_calendar = create(:school_calendar_with_one_step, year: 2016)
    daily_frequency = create(:daily_frequency, frequency_date: "04/01/2016", school_calendar: school_calendar)
    student = create(:student)
    teacher = create(:teacher)

    daily_frequencies = DailyFrequency.all
    students = Student.all

    subject = AttendanceRecordReport.build(
      entity_configuration,
      teacher,
      school_calendar.year,
      "01/01/2016",
      "01/01/2016",
      daily_frequencies,
      students
    ).render

    expect(subject).to be_truthy
  end
end
