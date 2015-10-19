require 'rails_helper'

RSpec.describe RecoveryDiaryRecordStudent, type: :model do
  subject(:recovery_diary_record_student) { build(:recovery_diary_record_student) }

  describe 'attributes' do
    it { expect(subject).to respond_to(:score) }
  end

  describe 'associations' do
    it { expect(subject).to belong_to(:recovery_diary_record) }
    it { expect(subject).to belong_to(:student) }
  end
end
