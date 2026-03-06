require 'rails_helper'

RSpec.describe Api::DisciplineRecordsCounter do
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
        year: year
      )
    end

    it 'returns an array of 11 entries with label and count' do
      result = subject.call

      expect(result.size).to eq(11)
      expect(result).to all(include(:label, :count))
    end

    it 'returns zero counts when no records exist' do
      result = subject.call

      result.each do |entry|
        expect(entry[:count]).to eq(0), "Expected 0 for #{entry[:label]}, got #{entry[:count]}"
      end
    end

    it 'counts daily frequencies correctly' do
      create(
        :daily_frequency,
        classroom: classroom,
        discipline: discipline,
        unity: unity,
        frequency_date: Date.current,
        school_calendar: classroom.calendar.school_calendar
      )

      result = subject.call
      entry = result.find { |e| e[:label] == I18n.t('navigation.daily_frequencies') }

      expect(entry[:count]).to eq(1)
    end
  end
end
