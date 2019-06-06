require 'rails_helper'

RSpec.describe StudentEnrollmentsList, type: :service do
  let(:school_calendar) { create(:school_calendar_with_one_step, year: 2016) }
  let(:avaliation) { create(:avaliation, school_calendar: school_calendar, test_date: "04/01/2016") }
  let(:daily_note) { create(:daily_note, avaliation: avaliation) }
  let(:student) { create(:student) }
  let(:student_enrollment) { create(:student_enrollment, student: student) }

  subject do
    StudentEnrollmentsList.new(
      classroom: daily_note.classroom,
      discipline: daily_note.discipline,
      date: Time.now.to_date,
      score_type: StudentEnrollmentScoreTypeFilters::NUMERIC,
      search_type: :by_date
    )
  end

  before do
    daily_note.classroom.student_enrollments << student_enrollment
    student_enrollment_classroom = daily_note.classroom.student_enrollment_classrooms.first
    frequency_start_at =  Date.parse("#{school_calendar.year}-01-01") 
    student_enrollment_classroom.update_attribute(:joined_at, frequency_start_at)
  end

  it "should return the student enrollments" do
    list = subject.student_enrollments

    expect(subject.student_enrollments.count).to equal 1
  end
end
