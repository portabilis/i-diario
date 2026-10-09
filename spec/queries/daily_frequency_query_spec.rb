require 'rails_helper'

RSpec.describe DailyFrequencyQuery, type: :query do
  # Segunda e terça da semana anterior: dias letivos já passados e dentro da mesma etapa do calendário
  let(:first_date) { Date.current.beginning_of_week - 1.week }
  let(:second_date) { first_date + 1.day }
  let(:classroom) { create(:classroom, :with_classroom_semester_steps) }
  let(:discipline) { create(:discipline) }
  let(:other_discipline) { create(:discipline) }

  describe '.call' do
    # Criadas fora de ordem para que a ordem de inserção não coincida com a ordem esperada
    before do
      [
        [second_date, 4],
        [first_date, 7],
        [first_date, 9],
        [second_date, 2],
        [first_date, 1],
        [first_date, 3]
      ].each { |date, class_number| create_daily_frequency(date, class_number) }
    end

    it 'returns the daily frequencies ordered by date and class number' do
      daily_frequencies = described_class.call(
        classroom_id: classroom.id,
        frequency_date: first_date..second_date,
        all_students_frequencies: true
      )

      dates_and_class_numbers = daily_frequencies.map { |daily_frequency|
        [daily_frequency.frequency_date, daily_frequency.class_number]
      }

      expect(dates_and_class_numbers).to eq(
        [
          [first_date, 1],
          [first_date, 3],
          [first_date, 7],
          [first_date, 9],
          [second_date, 2],
          [second_date, 4]
        ]
      )
    end

    it 'returns only the daily frequencies of the informed discipline and class numbers' do
      create_daily_frequency(first_date, 5, other_discipline)

      daily_frequencies = described_class.call(
        classroom_id: classroom.id,
        frequency_date: first_date..second_date,
        discipline_id: discipline.id,
        class_numbers: '1,3'
      )

      expect(daily_frequencies.map(&:class_number)).to eq([1, 3])
    end
  end

  def create_daily_frequency(date, class_number, frequency_discipline = discipline)
    create(
      :daily_frequency,
      classroom: classroom,
      discipline: frequency_discipline,
      frequency_date: date,
      class_number: class_number,
      period: Periods::MATUTINAL
    )
  end
end
