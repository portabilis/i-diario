require 'rails_helper'

RSpec.describe AbsenceCountService, type: :service do
  let(:student) { create(:student) }
  let(:classroom) { create(:classroom, :current, period: '4') }
  let(:discipline) { create(:discipline) }
  let(:school_calendar) { create(:school_calendar_with_one_step, :current, unity: classroom.unity) }
  let(:start_date) { school_calendar.steps.first.start_at }
  let(:end_date) { school_calendar.steps.first.end_at }
  let(:daily_frequency_1) do
    create(
      :daily_frequency,
      frequency_date: "04/01/#{school_calendar.year}",
      classroom: classroom,
      school_calendar: school_calendar,
      period: 1
    )
  end
  let(:daily_frequency_student_present_1) do
    create(
      :daily_frequency_student,
      student: student,
      daily_frequency: daily_frequency_1,
      present: true
    )
  end
  let(:daily_frequency_student_absent_1) do
    create(
      :daily_frequency_student,
      student: student,
      daily_frequency: daily_frequency_1,
      present: false
    )
  end
  let(:daily_frequency_2) do
    create(
      :daily_frequency,
      frequency_date: "04/01/#{school_calendar.year}",
      classroom: classroom,
      school_calendar: school_calendar,
      period: 2
    )
  end
  let(:daily_frequency_student_present_2) do
    create(
      :daily_frequency_student,
      student: student,
      daily_frequency: daily_frequency_2,
      present: true
    )
  end
  let(:daily_frequency_student_absent_2) do
    create(
      :daily_frequency_student,
      student: student,
      daily_frequency: daily_frequency_2,
      present: false
    )
  end
  let(:daily_frequency_3) do
    create(
      :daily_frequency,
      frequency_date: "04/01/#{school_calendar.year}",
      classroom: classroom,
      discipline: discipline,
      class_number: 1,
      school_calendar: school_calendar,
      period: 1
    )
  end
  let(:daily_frequency_student_present_3) do
    create(
      :daily_frequency_student,
      student: student,
      daily_frequency: daily_frequency_3,
      present: true
    )
  end
  let(:daily_frequency_student_absent_3) do
    create(
      :daily_frequency_student,
      student: student,
      daily_frequency: daily_frequency_3,
      present: false
    )
  end
  let(:daily_frequency_4) do
    create(
      :daily_frequency,
      frequency_date: "04/01/#{school_calendar.year}",
      classroom: classroom,
      discipline: discipline,
      class_number: 1,
      school_calendar: school_calendar,
      period: 2
    )
  end
  let(:daily_frequency_student_present_4) do
    create(
      :daily_frequency_student,
      student: student,
      daily_frequency: daily_frequency_4,
      present: true
    )
  end
  let(:daily_frequency_student_absent_4) do
    create(
      :daily_frequency_student,
      student: student,
      daily_frequency: daily_frequency_4,
      present: false
    )
  end

  describe '#count' do
    context 'with general presence' do
      subject do
        AbsenceCountService.new(student, classroom, start_date, end_date)
      end

      context 'when a student is absent in both periods' do
        it 'count as only one absence' do
          allow(subject).to receive(:student_frequencies_in_date_range).and_return(
            [daily_frequency_student_absent_1, daily_frequency_student_absent_2]
          )

          expect(subject.count).to eq(1)
        end
      end

      context 'when a student is present in at least one period' do
        it 'does not count any absence' do
          allow(subject).to receive(:student_frequencies_in_date_range).and_return(
            [daily_frequency_student_present_1, daily_frequency_student_absent_2]
          )

          expect(subject.count).to eq(0)
        end
      end

      context 'when a student is present in both periods' do
        it 'does not count any absence' do
          allow(subject).to receive(:student_frequencies_in_date_range).and_return(
            [daily_frequency_student_present_1, daily_frequency_student_present_2]
          )

          expect(subject.count).to eq(0)
        end
      end
    end

    context 'with presence by components' do
      subject do
        AbsenceCountService.new(student, classroom, start_date, end_date, discipline)
      end

      context 'when a student is absent in both periods for the same class number' do
        it 'does count only one absence' do
          allow(subject).to receive(:student_frequencies_in_date_range).and_return(
            [daily_frequency_student_absent_3, daily_frequency_student_absent_4]
          )

          expect(subject.count).to eq(1)
        end
      end

      context 'when a student is present in at least one period for the same class number' do
        it 'does not count any absence' do
          allow(subject).to receive(:student_frequencies_in_date_range).and_return(
            [daily_frequency_student_present_3, daily_frequency_student_absent_4]
          )

          expect(subject.count).to eq(0)
        end
      end

      context 'when a student is present in btoth periods for the same class number' do
        it 'does not count any absence' do
          allow(subject).to receive(:student_frequencies_in_date_range).and_return(
            [daily_frequency_student_present_3, daily_frequency_student_present_4]
          )

          expect(subject.count).to eq(0)
        end
      end
    end
  end
end
