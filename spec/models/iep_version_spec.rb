require 'rails_helper'

RSpec.describe IepVersion, type: :model do
  describe 'validations' do
    subject { build(:iep_version) }

    it { expect(subject).to validate_presence_of(:name) }
    it { expect(subject).to validate_presence_of(:published_at) }
    it { expect(subject).to validate_length_of(:name).is_at_least(3) }

    it 'rejects a name shorter than the client-side minimum' do
      expect(build(:iep_version, name: 'ab')).not_to be_valid
    end
  end

  describe '.current' do
    it 'returns only the active version' do
      plan = create(:individualized_educational_plan)
      active = create(:iep_version, :current, iep: plan)
      create(:iep_version, iep: plan)

      expect(described_class.current).to contain_exactly(active)
    end
  end

  describe '.recent_first' do
    it 'orders by published_at descending' do
      plan = create(:individualized_educational_plan)
      older = create(:iep_version, iep: plan, published_at: 2.days.ago)
      newer = create(:iep_version, iep: plan, published_at: 1.day.ago)

      expect(described_class.recent_first.to_a).to eq([newer, older])
    end
  end
end
