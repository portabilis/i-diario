require 'rails_helper'

RSpec.describe Api::DisciplineRecordsDestroyer do
  let(:year) { Date.current.year }
  let(:unity) { create(:unity) }
  let(:discipline) { create(:discipline) }
  let(:classroom) do
    create(:classroom, :with_classroom_semester_steps, unity: unity, year: year)
  end
  let!(:classrooms_grade) do
    create(:classrooms_grade, classroom: classroom)
  end

  around(:each) do |example|
    Entity.find_by_domain('test.host').using_connection do
      example.run
    end
  end

  describe '#call' do
    subject do
      described_class.new(
        unities: [unity.api_code],
        courses: [],
        grades: [],
        disciplines: [discipline.api_code],
        year: year,
        user: 'test-user'
      )
    end

    it 'destroys daily frequencies and returns count' do
      create(
        :daily_frequency,
        classroom: classroom,
        discipline: discipline,
        unity: unity,
        frequency_date: Date.current,
        school_calendar: classroom.calendar.school_calendar
      )

      expect { subject.call }.to change(DailyFrequency, :count).by(-1)
    end

    it 'does not destroy records outside the filter scope' do
      other_discipline = create(:discipline)

      create(
        :daily_frequency,
        classroom: classroom,
        discipline: other_discipline,
        unity: unity,
        frequency_date: Date.current,
        school_calendar: classroom.calendar.school_calendar
      )

      expect { subject.call }.not_to change(DailyFrequency, :count)
    end

    it 'returns the exact total number of destroyed records' do
      daily_frequency = create(
        :daily_frequency,
        classroom: classroom,
        discipline: discipline,
        unity: unity,
        frequency_date: Date.current,
        school_calendar: classroom.calendar.school_calendar
      )
      children_count = DailyFrequencyStudent.where(daily_frequency_id: daily_frequency.id).count

      total = subject.call
      expect(total).to eq(1 + children_count)
    end

    it 'runs within a transaction and rolls back on error' do
      create(
        :daily_frequency,
        classroom: classroom,
        discipline: discipline,
        unity: unity,
        frequency_date: Date.current,
        school_calendar: classroom.calendar.school_calendar
      )

      allow_any_instance_of(described_class).to receive(:destroy_transfer_notes).and_raise(StandardError)

      expect {
        subject.call rescue nil
      }.not_to change(DailyFrequency, :count)
    end

    it 'returns zero when no records match' do
      total = subject.call
      expect(total).to eq(0)
    end
  end
end
