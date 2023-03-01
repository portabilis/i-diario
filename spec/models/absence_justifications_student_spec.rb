require 'rails_helper'

RSpec.describe AbsenceJustificationsStudent, type: :model do
  describe 'associations' do
    subject(:absence_justifications_student) { create(:absence_justifications_student) }

    it { expect(subject).to belong_to(:absence_justification) }
    it { expect(subject).to belong_to(:student) }
  end

  describe 'callbacks' do
    context  'should remove justification from student frequencies ' do
      let!(:absence_justifications_student) { create(:absence_justifications_student, :with_daily_frequency) }

      it 'ensures justification was removed' do
        expect(DailyFrequencyStudent.first.absence_justification_student_id).to equal absence_justifications_student.id

        absence_justifications_student.absence_justification.destroy!

        expect(DailyFrequencyStudent.first.absence_justification_student_id).to be_nil
      end
    end
  end
end
