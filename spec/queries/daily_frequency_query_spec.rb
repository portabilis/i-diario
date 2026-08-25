require 'rails_helper'

RSpec.describe DailyFrequencyQuery, type: :query do
  # Segunda e terça da semana corrente: dias letivos dentro da mesma etapa do calendário
  let(:first_date) { Date.current.beginning_of_week }
  let(:second_date) { Date.current.beginning_of_week + 1.day }
  let(:classroom) { create(:classroom, :with_classroom_semester_steps) }
  let(:discipline) { create(:discipline) }

  describe '.call' do
    # Criadas fora de ordem para que a ordem de inserção não coincida com a ordem esperada
    let!(:daily_frequencies) {
      [
        [second_date, 4],
        [first_date, 7],
        [first_date, 9],
        [second_date, 2],
        [first_date, 1],
        [first_date, 3]
      ].map { |date, class_number| create_daily_frequency(date, class_number) }
    }

    subject(:daily_frequencies_found) {
      described_class.call(
        classroom_id: classroom.id,
        frequency_date: first_date..second_date,
        all_students_frequencies: true
      )
    }

    it 'returns the daily frequencies ordered by date and class number' do
      dates_and_class_numbers = daily_frequencies_found.map { |daily_frequency|
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
  end

  def create_daily_frequency(date, class_number)
    create(
      :daily_frequency,
      classroom: classroom,
      discipline: discipline,
      frequency_date: date,
      class_number: class_number,
      period: Periods::MATUTINAL
    )
  end
end
