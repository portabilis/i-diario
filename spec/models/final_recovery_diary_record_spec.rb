require 'rails_helper'

RSpec.describe FinalRecoveryDiaryRecord, type: :model do
  subject(:final_recovery_diary_record) { build(:final_recovery_diary_record) }

  describe 'associations' do
    it { expect(subject).to belong_to(:recovery_diary_record).dependent(:destroy) }
    it { expect(subject).to belong_to(:school_calendar) }
  end

  describe 'validations' do
    it { expect(subject).to validate_presence_of(:recovery_diary_record) }
    it { expect(subject).to validate_presence_of(:school_calendar) }

    it 'validates uniqueness per school_calendar, classroom and discipline' do
    end
  end
end
