require 'rails_helper'

RSpec.describe AvaliationRecoveryLowestNote, type: :model do
  describe 'associations' do
    it { expect(subject).to belong_to(:recovery_diary_record) }
  end

  describe 'validations' do
    #
  end
end
