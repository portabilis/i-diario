require 'rails_helper'

RSpec.describe CreateAbsenceJustificationsService, type: :service do

  context 'when the params are correct' do
    subject(:create_absence_justifications) {
      CreateAbsenceJustificationsService.call(
        class_numbers, params, uinty, teacher, school_calendar, user
      )
    }

    it 'is_expected' do
      expect(create_absence_justifications.size).to eq(3)
    end

    it 'is_expected' do
      expect(create_absence_justifications).to be_truthy
    end
  end
end
