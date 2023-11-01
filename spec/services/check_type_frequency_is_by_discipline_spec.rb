require 'rails_helper'

RSpec.describe CheckTypeFrequencyByDisciplineService, type: :service do
  context 'when the params are correct' do
    subject(:frequency_by_discipline) {
      CheckTypeFrequencyByDisciplineService.call(
        class_numbers, params, uinty, teacher, school_calendar, user
      )
    }

    it 'is_expected' do
      expect(frequency_by_discipline.size).to eq(3)
    end

    it 'is_expected' do
      expect(frequency_by_discipline).to be_truthy
    end
  end
end
