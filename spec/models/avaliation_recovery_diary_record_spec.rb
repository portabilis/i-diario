require 'rails_helper'

RSpec.describe AvaliationRecoveryDiaryRecord, type: :model do
  let(:current_user) { create(:user) }

  subject(:avaliation_recovery_diary_record) {
    build(
      :avaliation_recovery_diary_record,
      :with_teacher_discipline_classroom
    )
  }

  before do
    current_user.current_classroom_id = subject.classroom_id
    current_user.current_discipline_id = subject.discipline_id
    allow(subject.recovery_diary_record).to receive(:current_user).and_return(current_user)
  end

  describe 'associations' do
    it { expect(subject).to belong_to(:recovery_diary_record) }
    it { expect(subject).to belong_to(:avaliation) }
  end

  describe 'validations' do
    it { expect(subject).to validate_presence_of(:recovery_diary_record) }
    it { expect(subject).to validate_presence_of(:avaliation) }
  end
end
