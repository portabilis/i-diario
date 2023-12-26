require 'rails_helper'

RSpec.describe CreateAbsenceJustificationsService, type: :service do
  let!(:class_numbers) { ['1', '2', '3'] }
  let(:school_calendar) { create(:school_calendar) }
  let!(:classroom) { create(:classroom, unity: school_calendar.unity) }
  let(:student) { create(:student) }
  let(:params) {
    {
      student_ids: [student.id],
      absence_date: '01/11/2023',
      justification: '',
      absence_date_end: '01/11/2023',
      unity_id: school_calendar.unity_id,
      classroom_id: classroom.id,
      period: '1'
    }
  }
  let(:user) { create(:user) }
  let!(:teacher) { create(:teacher) }

  describe 'when the params are correct' do
    subject(:create_absence_justifications) {
      CreateAbsenceJustificationsService.call(
        class_numbers, params, teacher, school_calendar.unity, school_calendar, user
      )
    }

    it 'Is expected that 3 absence_justifications will be created' do
      expect(create_absence_justifications.first.count).to eq(3)
    end

    it 'Is expected that the last absence_justification created will be returned' do
      expect(create_absence_justifications).to be_truthy
    end
  end

  describe 'when the params are incorrect' do
    it 'Is expected raises error when assigning the wrong type' do
      expect { CreateAbsenceJustificationsService.call(
        class_numbers, params, 123, school_calendar.unity, school_calendar, user
      ) }.to raise_error(ActiveRecord::AssociationTypeMismatch)
    end

    it 'Is expected returns nil if any parameter is nil' do
      expect(CreateAbsenceJustificationsService.call(
        class_numbers, params, teacher, school_calendar.unity, nil, user
      )).to be_nil
    end
  end
end
