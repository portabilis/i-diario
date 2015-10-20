require 'rails_helper'

RSpec.describe RecoveryDiaryRecord, type: :model do
  subject(:recovery_diary_record) { build(:recovery_diary_record) }

  describe 'attributes' do
    it { expect(subject).to respond_to(:recorded_at) }
  end

  describe 'associations' do
    it { expect(subject).to belong_to(:unity) }
    it { expect(subject).to belong_to(:classroom) }
    it { expect(subject).to belong_to(:discipline) }
    it { expect(subject).to have_many(:students).dependent(:destroy) }
    it { expect(subject).to have_one(:school_term_recovery_diary_record) }
    it { expect(subject).to have_one(:final_recovery_diary_record) }
  end

  describe 'validations' do
    it { expect(subject).to validate_presence_of(:unity) }
    it { expect(subject).to validate_presence_of(:classroom) }
    it { expect(subject).to validate_presence_of(:discipline) }
    it { expect(subject).to validate_presence_of(:recorded_at) }
  end
end
