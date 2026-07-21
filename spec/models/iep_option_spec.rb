require 'rails_helper'

RSpec.describe IepOption, type: :model do
  describe 'validations' do
    subject { build(:iep_option) }

    it { expect(subject).to validate_presence_of(:kind) }
    it { expect(subject).to validate_presence_of(:description) }
  end

  describe '.by_kind' do
    let!(:communication) { create(:iep_option, :communication_profile) }
    let!(:support) { create(:iep_option, :support_type) }

    it 'filters by the kind symbol' do
      expect(described_class.by_kind(:communication_profile)).to contain_exactly(communication)
    end

    it 'filters by the kind integer value' do
      expect(described_class.by_kind(IepOptionKinds::SUPPORT_TYPE)).to contain_exactly(support)
    end
  end

  describe '.enabled' do
    it 'returns only active options' do
      active = create(:iep_option, active: true)
      create(:iep_option, active: false)

      expect(described_class.enabled).to contain_exactly(active)
    end
  end

  describe 'IepOptionKinds.value_of' do
    it 'resolves a known kind symbol to its integer value' do
      expect(IepOptionKinds.value_of(:communication_profile))
        .to eq(IepOptionKinds::COMMUNICATION_PROFILE)
    end

    it 'passes an integer through unchanged' do
      expect(IepOptionKinds.value_of(IepOptionKinds::SUPPORT_TYPE))
        .to eq(IepOptionKinds::SUPPORT_TYPE)
    end

    it 'returns nil for an unknown kind (does not raise)' do
      expect(IepOptionKinds.value_of(:bogus)).to be_nil
    end
  end

  describe '#to_s' do
    it 'returns the description (label used by the selects)' do
      option = build(:iep_option, description: 'Comunicação alternativa')

      expect(option.to_s).to eq('Comunicação alternativa')
    end
  end
end
