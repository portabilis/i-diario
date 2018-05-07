require 'rails_helper'

RSpec.describe DailyFrequenciesCreator, type: :service do
  let(:classroom) { create(:classroom) }
  let(:frequency_start_at) { Date.parse("#{school_calendar.year}-01-01") }
  let(:student_enrollment) { create(:student_enrollment) }
  let(:school_calendar) do
    create(:school_calendar_with_one_step, unity: classroom.unity, year: Date.current.year)
  end

  before do
    classroom.student_enrollments << student_enrollment
  end

  it 'allows to create frequencies to current date when frequency_date argument is null' do
    student_enrollment_classroom = classroom.student_enrollment_classrooms.first
    student_enrollment_classroom.update_attribute(:joined_at, frequency_start_at)

    creator = described_class.new({
      unity: classroom.unity,
      classroom_id: classroom.id,
      school_calendar: school_calendar
    })

    expect { creator.find_or_create! }.to change { DailyFrequency.count }
  end

  it 'does not create frequencies when frequency_date argument is not a valid one' do
    student_enrollment_classroom = classroom.student_enrollment_classrooms.first
    student_enrollment_classroom.update_attribute(:joined_at, frequency_start_at - 1.day)

    creator = described_class.new({
      unity: classroom.unity,
      classroom_id: classroom.id,
      school_calendar: school_calendar,
      frequency_date: frequency_start_at - 1.day
    })

    expect { creator.find_or_create! }.to_not change { DailyFrequency.count }
  end

end
