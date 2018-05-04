require 'rails_helper'

RSpec.describe DailyFrequenciesCreator, type: :service do
  let(:classroom) { create(:classroom) }

  it 'allows to create frequencies to current date when frequency_date argument is null' do
    school_calendar = create(:school_calendar_with_one_step, unity: classroom.unity, year: Date.current.year)
    frequency_start_at = Date.parse("#{school_calendar.year}-01-01")
    student_enrollment = create(:student_enrollment)
    classroom.student_enrollments << student_enrollment
    student_enrollment_classroom = classroom.student_enrollment_classrooms.first
    student_enrollment_classroom.update_attribute(:joined_at, frequency_start_at)

    creator = described_class.new({
      unity: classroom.unity,
      classroom_id: classroom.id,
      school_calendar: school_calendar
    })

    expect { creator.find_or_create! }.to change { DailyFrequency.count }
  end

end
