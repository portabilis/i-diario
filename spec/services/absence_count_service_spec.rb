require 'rails_helper'

RSpec.describe AbsenceCountService, type: :service do
  let(:student) { create(:student) }
  let(:discipline) { create(:discipline) }
  let(:classroom) {
    create(
      :classroom,
      :with_classroom_semester_steps,
      period: Periods::FULL
    )
  }
  let(:step) { classroom.calendar.classroom_steps.first }
  let(:start_date) { step.start_at }
  let(:end_date) { step.end_at }

  describe '#count' do
    context 'with general presence' do
      subject do
        described_class.new(do_not_send_justified_absence: false)
      end
      context 'when a student is absent in both periods' do
        it 'count as only one absence' do
          allow(subject).to receive(:student_frequencies_in_date_range).and_return(
            [create_daily_frequency_student(create_daily_frequency(1), false),
             create_daily_frequency_student(create_daily_frequency(2), false)]
          )

          expect(subject.count(student, classroom, start_date, end_date)).to eq(1)
        end
      end

      context 'when a student is present in at least one period' do
        it 'does not count any absence' do
          allow(subject).to receive(:student_frequencies_in_date_range).and_return(
            [create_daily_frequency_student(create_daily_frequency(1), true),
             create_daily_frequency_student(create_daily_frequency(2), false)]
          )

          expect(subject.count(student, classroom, start_date, end_date)).to eq(0)
        end
      end

      context 'when a student is present in both periods' do
        it 'does not count any absence' do
          allow(subject).to receive(:student_frequencies_in_date_range).and_return(
            [create_daily_frequency_student(create_daily_frequency(1), true),
             create_daily_frequency_student(create_daily_frequency(2), true)]
          )

          expect(subject.count(student, classroom, start_date, end_date)).to eq(0)
        end
      end
    end

    context 'with presence by components' do
      subject do
        described_class.new(do_not_send_justified_absence: false)
      end

      context 'when a student is absent in both periods for the same class number' do
        it 'does count only one absence' do
          allow(subject).to receive(:student_frequencies_in_date_range).and_return(
            [create_daily_frequency_student(create_daily_frequency(1, discipline, 1), false),
             create_daily_frequency_student(create_daily_frequency(2, discipline, 1), false)]
          )

          expect(subject.count(student, classroom, start_date, end_date, discipline)).to eq(1)
        end
      end

      context 'when a student is present in at least one period for the same class number' do
        it 'does not count any absence' do
          allow(subject).to receive(:student_frequencies_in_date_range).and_return(
            [create_daily_frequency_student(create_daily_frequency(1, discipline, 1), true),
             create_daily_frequency_student(create_daily_frequency(2, discipline, 1), false)]
          )

          expect(subject.count(student, classroom, start_date, end_date, discipline)).to eq(0)
        end
      end

      context 'when a student is present in btoth periods for the same class number' do
        it 'does not count any absence' do
          allow(subject).to receive(:student_frequencies_in_date_range).and_return(
            [create_daily_frequency_student(create_daily_frequency(1, discipline, 1), true),
             create_daily_frequency_student(create_daily_frequency(2, discipline, 1), true)]
          )

          expect(subject.count(student, classroom, start_date, end_date, discipline)).to eq(0)
        end
      end
    end
  end

  def create_daily_frequency(period, discipline = nil, class_number = nil)
    create(
      :daily_frequency,
      frequency_date: "04/01/#{classroom.year}",
      classroom: classroom,
      discipline: discipline,
      class_number: class_number,
      school_calendar: classroom.calendar.school_calendar,
      period: period
    )
  end

  def create_daily_frequency_student(daily_frequency, presence)
    create(
      :daily_frequency_student,
      student: student,
      daily_frequency: daily_frequency,
      present: presence
    )
  end
end
