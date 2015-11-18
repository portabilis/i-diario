require 'rails_helper'

RSpec.describe TestSettingTest, type: :model do
  describe 'attributes' do
    it { expect(subject).to respond_to(:description) }
    it { expect(subject).to respond_to(:weight) }
    it { expect(subject).to respond_to(:allow_break_up) }
  end

  describe 'associations' do
    it { expect(subject).to belong_to(:test_setting) }
  end

  describe 'validations' do
    it { expect(subject).to validate_presence_of(:description) }
    it { expect(subject).to validate_presence_of(:weight) }
  end
end
