require 'rails_helper'

RSpec.describe AvaliationRecoveryDiaryRecord, type: :model do
  subject(:avaliation_recovery_diary_record) { build(:avaliation_recovery_diary_record) }

  describe 'associations' do
    # FIXME: Ajustar junto com o refactor das factories
    xit { expect(subject).to belong_to(:recovery_diary_record).dependent(:destroy) }
    xit { expect(subject).to belong_to(:avaliation) }
  end

  describe 'validations' do
    # FIXME: Ajustar junto com o refactor das factories
    xit { expect(subject).to validate_presence_of(:recovery_diary_record) }
    # TODO Correct test
    # it { expect(subject).to validate_presence_of(:avaliation) }
  end
end
