require 'rails_helper'

RSpec.describe CustomRoundingTableValue, type: :model do
  let(:custom_rounding_table) { create(:custom_rounding_table) }

  subject do
    build(
      :custom_rounding_table_value
    )
  end

  describe 'attributes' do
    it { expect(subject).to respond_to(:label) }
    it { expect(subject).to respond_to(:action) }
  end

  describe 'associations' do
    it { expect(subject).to belong_to(:custom_rounding_table) }
  end

  describe 'validations' do
    it { expect(subject).to validate_presence_of(:label) }
  end

  describe '.ordered_asc' do
    it 'orders by label asc' do
      create(:custom_rounding_table_value, label: '2', custom_rounding_table: custom_rounding_table)
      create(:custom_rounding_table_value, label: '0', custom_rounding_table: custom_rounding_table)
      create(:custom_rounding_table_value, label: '1', custom_rounding_table: custom_rounding_table)

      expect(CustomRoundingTableValue.ordered_asc.first.label).to eq('0')
    end
  end

  describe '.ordered' do
    it 'orders by label desc' do
      create(:custom_rounding_table_value, label: '1', custom_rounding_table: custom_rounding_table)
      create(:custom_rounding_table_value, label: '2', custom_rounding_table: custom_rounding_table)
      create(:custom_rounding_table_value, label: '0', custom_rounding_table: custom_rounding_table)

      expect(CustomRoundingTableValue.ordered.first.label).to eq('2')
    end
  end
end
