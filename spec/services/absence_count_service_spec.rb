require 'rails_helper'

RSpec.describe AbsenceCountService, type: :service do
  let(:classroom) { create(:classroom, :current) }
  let(:school_calendar) { create(:school_calendar_with_one_step, :current, unity: classroom.unity) }

  let!(:daily_frequency_1) do
    create(
      :daily_frequency,
      frequency_date: "04/01/#{school_calendar.year}",
      classroom: classroom,
      school_calendar: school_calendar,
      period: 1
    )
  end
  let!(:daily_frequency_2) do
    create(
      :daily_frequency,
      frequency_date: "04/01/#{school_calendar.year}",
      classroom: classroom,
      school_calendar: school_calendar,
      period: 2
    )
  end

  describe '#count_absences' do
    context 'when a student is absent in both periods' do
      let!(:daily_frequency_student_1) do
        create(
          :daily_frequency_student,
          daily_frequency: daily_frequency_1,
          present: false
        )
      end
      let!(:daily_frequency_student_2) do
        create(
          :daily_frequency_student,
          daily_frequency: daily_frequency_2,
          present: false
        )
      end
      let!(:daily_frequency_students) do
        [daily_frequency_student_1, daily_frequency_student_2]
      end

      subject do
        AbsenceCountService.new(daily_frequency_students)
      end

      it 'count as only one absence' do
        expect(subject.count_absences).to eq(1)
      end
    end
  end

  describe '#count_absences' do
    context 'when a student is present in at least on period' do
      let!(:daily_frequency_student_1) do
        create(
          :daily_frequency_student,
          daily_frequency: daily_frequency_1,
          present: true
        )
      end
      let!(:daily_frequency_student_2) do
        create(
          :daily_frequency_student,
          daily_frequency: daily_frequency_2,
          present: false
        )
      end
      let!(:daily_frequency_students) do
        [daily_frequency_student_1, daily_frequency_student_2]
      end

      subject do
        AbsenceCountService.new(daily_frequency_students)
      end

      it 'does not count any absence' do
        expect(subject.count_absences).to eq(0)
      end
    end
  end

  describe '#count_absences' do
    context 'when a student is present in both periods' do
      let!(:daily_frequency_student_1) do
        create(
          :daily_frequency_student,
          daily_frequency: daily_frequency_1,
          present: true
        )
      end
      let!(:daily_frequency_student_2) do
        create(
          :daily_frequency_student,
          daily_frequency: daily_frequency_2,
          present: true
        )
      end
      let!(:daily_frequency_students) do
        [daily_frequency_student_1, daily_frequency_student_2]
      end

      subject do
        AbsenceCountService.new(daily_frequency_students)
      end

      it 'does not count any absence' do
        expect(subject.count_absences).to eq(0)
      end
    end
  end
end
