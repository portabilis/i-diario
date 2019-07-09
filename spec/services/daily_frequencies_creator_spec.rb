require 'rails_helper'

RSpec.describe DailyFrequenciesCreator, type: :service do
  let(:discipline) { create(:discipline) }
  let(:classroom) { create(:classroom, :current) }
  let(:default_class_numbers) { ['1'] }
  let(:two_class_numbers) { ['1', '2'] }
  let(:period) { 1 }
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
      school_calendar: school_calendar,
      period: period
    })

    expect { creator.find_or_create! }.to change { DailyFrequency.count }.to(1)
  end

  it 'does not create frequencies when frequency_date argument is not a valid one' do
    student_enrollment_classroom = classroom.student_enrollment_classrooms.first
    student_enrollment_classroom.update_attribute(:joined_at, frequency_start_at - 1.day)

    creator = described_class.new({
      unity: classroom.unity,
      classroom_id: classroom.id,
      school_calendar: school_calendar,
      frequency_date: frequency_start_at - 1.day,
      period: period
    })

    expect { creator.find_or_create! }.to_not change { DailyFrequency.count }
  end

  it 'allows to create frequencies custom class numbers in the params' do
    student_enrollment_classroom = classroom.student_enrollment_classrooms.first
    student_enrollment_classroom.update_attribute(:joined_at, frequency_start_at)

    creator = described_class.new({
      unity: classroom.unity,
      classroom_id: classroom.id,
      school_calendar: school_calendar,
      class_numbers: default_class_numbers,
      discipline_id: discipline.id,
      period: period
    })

    creator.find_or_create!
    daily_frequency = DailyFrequency.last

    expect(daily_frequency.class_number).to eq 1
  end

  it 'allows to create frequencies with two custom class numbers in the params' do
    student_enrollment_classroom = classroom.student_enrollment_classrooms.first
    student_enrollment_classroom.update_attribute(:joined_at, frequency_start_at)

    creator = described_class.new({
      unity: classroom.unity,
      classroom_id: classroom.id,
      school_calendar: school_calendar,
      class_numbers: two_class_numbers,
      discipline_id: discipline.id,
      period: period
    })

    expect { creator.find_or_create! }.to change { DailyFrequency.count }.to(2)
  end

  it 'should create daily_frequency_students for available student_enrollment_classrooms' do
    student_enrollment_classroom = classroom.student_enrollment_classrooms.first
    student_enrollment_classroom.update_attribute(:joined_at, frequency_start_at)

    creator = described_class.new({
      unity: classroom.unity,
      classroom_id: classroom.id,
      school_calendar: school_calendar,
      class_numbers: default_class_numbers,
      discipline_id: discipline.id,
      period: period
    })

    creator.find_or_create!
    daily_frequency = creator.daily_frequencies[0]
    daily_frequency_student_exists = daily_frequency.students.where(student_id: student_enrollment.student_id).exists?

    expect(daily_frequency_student_exists).to be true
  end

  it 'should not create daily_frequency_students for students exempted from discipline' do
    student_enrollment_classroom = classroom.student_enrollment_classrooms.first
    student_enrollment_classroom.update_attribute(:joined_at, frequency_start_at)

    StudentEnrollmentExemptedDiscipline.create!(
      student_enrollment: student_enrollment,
      discipline: discipline,
      steps: school_calendar.steps.count.times.map{|i| "#{i+1}"}.join(',')
    )

    creator = described_class.new({
      unity: classroom.unity,
      classroom_id: classroom.id,
      school_calendar: school_calendar,
      class_numbers: default_class_numbers,
      discipline_id: discipline.id,
      period: period
    })

    creator.find_or_create!
    daily_frequency = creator.daily_frequencies[0]
    daily_frequency_student_exists = daily_frequency.students.where(student_id: student_enrollment.student_id).exists?

    expect(daily_frequency_student_exists).to be false
  end
end
