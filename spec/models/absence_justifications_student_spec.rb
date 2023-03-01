require 'rails_helper'

RSpec.describe AbsenceJustificationsStudent, type: :model do
  subject(:absence_justifications_student) { create(:absence_justifications_student) }

  describe 'associations' do
    it { expect(subject).to belong_to(:absence_justification) }
    it { expect(subject).to belong_to(:student) }
  end
end
