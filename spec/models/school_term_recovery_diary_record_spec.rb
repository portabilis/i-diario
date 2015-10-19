require 'rails_helper'

RSpec.describe SchoolTermRecoveryDiaryRecord, type: :model do
  subject(:school_term_recovery_diary_record) { build(:school_term_recovery_diary_record) }

  describe 'associations' do
    it { expect(subject).to belong_to(:recovery_diary_record).dependent(:destroy) }
    it { expect(subject).to belong_to(:school_calendar_step) }
  end

  describe 'validations' do
    it { expect(subject).to validate_presence_of(:recovery_diary_record) }
    it { expect(subject).to validate_presence_of(:school_calendar_step) }
  end
end
