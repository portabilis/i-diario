require 'rails_helper'

RSpec.describe CustomRoundingTable, type: :model do
  subject do
    build(
      :custom_rounding_table
    )
  end

  describe 'attributes' do
    it { expect(subject).to respond_to(:name) }
    it { expect(subject).to respond_to(:year) }
    it { expect(subject).to respond_to(:unities) }
    it { expect(subject).to respond_to(:courses) }
    it { expect(subject).to respond_to(:grades) }
    it { expect(subject).to respond_to(:rounded_avaliations) }
  end

  describe 'associations' do
    it { expect(subject).to have_many(:custom_rounding_table_values) }
    it { expect(subject).to have_and_belong_to_many(:unities) }
    it { expect(subject).to have_and_belong_to_many(:courses) }
    it { expect(subject).to have_and_belong_to_many(:grades) }
  end

  describe 'validations' do
    it { expect(subject).to validate_presence_of(:name) }
    it { expect(subject).to validate_uniqueness_of(:name) }
    it { expect(subject).to validate_presence_of(:year) }
    it { expect(subject).to validate_presence_of(:unities) }
    it { expect(subject).to validate_presence_of(:courses) }
    it { expect(subject).to validate_presence_of(:grades) }
    it { expect(subject).to validate_presence_of(:rounded_avaliations) }
  end

  describe '.ordered' do
    it 'orders by name' do
      create(:custom_rounding_table, name: 'cc')
      create(:custom_rounding_table, name: 'aa')
      create(:custom_rounding_table, name: 'bb')

      expect(CustomRoundingTable.ordered.first.name).to eq('aa')
    end
  end

  describe '.ordered_by_year' do
    it 'orders by year desc' do
      create(:custom_rounding_table, name: 'cc', year: 2020)
      create(:custom_rounding_table, name: 'bb', year: 2022)
      create(:custom_rounding_table, name: 'aa', year: 2021)

      expect(CustomRoundingTable.ordered_by_year.first.year).to eq(2022)
    end
  end
end
