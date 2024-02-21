require 'rails_helper'
require 'enumerate_it'

RSpec.describe ScoreRounder, type: :service do
  let(:exam_rule) { double(:exam_rule, rounding_table: rounding_table) }
  let(:unity) { create(:unity) }
  let(:grade) { create(:grade) }
  let(:classroom) { create(:classroom, year: 2017, unity: unity, unity_id: unity.id, grades: [grade], exam_rule: exam_rule) }
  let(:rounding_table) { double(:rounding_table, values: rounding_table_values, id: 1) }
  let(:rounding_table_value) do
    double(:rounding_table_value, label: label, action: action, exact_decimal_place: exact_decimal_place)
  end
  let(:custom_rounding_table_value) do
    double(:custom_rounding_table_value,
           label: label,
           action: action,
           exact_decimal_place: exact_decimal_place)
  end
  let(:rounding_table_values) { [rounding_table_value] }
  let(:custom_rounding_table_values) { [custom_rounding_table_value] }
  let(:exact_decimal_place) { '' }
  let(:label) { '0' }
  let(:action) { RoundingTableAction::NONE }

  subject do
    ScoreRounder.new(classroom, RoundedAvaliations::NUMERICAL_EXAM)
  end

  shared_examples 'round' do
    describe '#round' do
      context 'when there is no rounding action' do
        let(:label) { '5' }
        let(:action) { RoundingTableAction::NONE }
        it 'should return the same score truncated' do
          expect(subject.round(8.555)).to be(8.5)
        end
      end

      context 'when rounding is below' do
        let(:label) { '9' }
        let(:action) { RoundingTableAction::BELOW }
        it 'should round to below' do
          expect(subject.round(5.912)).to be(5.0)
        end
      end

      context 'when rounding is above' do
        let(:label) { '8' }
        let(:action) { RoundingTableAction::ABOVE }
        it 'should round to above' do
          expect(subject.round(9.8)).to be(10.0)
        end
      end

      context 'when rounding is specific' do
        let(:label) { '9' }
        let(:action) { RoundingTableAction::SPECIFIC }
        let(:exact_decimal_place) { 5 }
        it 'should round to .5' do
          expect(subject.round(2.9999)).to be(2.5)
        end
      end

      context 'when number is complex' do
        let(:label) { '0' }
        let(:action) { RoundingTableAction::ABOVE }
        it 'it should round to above normally' do
          expect(subject.round(2.08)).to be(3.0)
        end
      end

      context 'when number is zero' do
        let(:label) { '0' }
        let(:action) { RoundingTableAction::NONE }
        it 'it should return zero' do
          expect(subject.round(0.0)).to be(0.0)
        end
      end

      context 'when number is 10.0' do
        let(:action) { RoundingTableAction::ABOVE }
        it 'should not round at all' do
          expect(subject.round(10.0)).to be(10.0)
        end
      end

      context 'when number is greater than 10.0' do
        let(:label) { '3' }
        let(:action) { RoundingTableAction::ABOVE }
        it 'should round to above normally' do
          expect(subject.round(12.3)).to be(13.0)
        end
      end

      context 'when number is nil' do
        let(:action) { RoundingTableAction::ABOVE }
        it 'should return zero' do
          skip "Logic returns nil"
          expect(subject.round(nil)).to be(0.0)
        end
      end
    end
  end

  context 'when has custom rounding table' do
    before do
      stub_rounding_table_value
      stub_custom_rounding_table
      stub_custom_rounding_table_value
    end

    it_behaves_like 'round'
  end

  context 'when does not have custom rounding table' do
    before do
      stub_rounding_table_value
      stub_emtpy_custom_rounding_table
    end

    it 'should return the same score truncated' do
      expect(subject.round(2.008)).to be(2.0)
      expect(subject.round(12.3)).to be(12.3)
      expect(subject.round(8.555)).to be(8.5)
      expect(subject.round(5.912)).to be(5.9)
      expect(subject.round(9.8)).to be(9.8)
    end
  end

  def stub_rounding_table_value
    stub_const('RoundingTableValue', Class.new)

    allow(RoundingTableValue).to receive(:find_by)
      .with(rounding_table_id: 1, label: label)
      .and_return(rounding_table_value)
  end

  def stub_custom_rounding_table_value
    stub_const('CustomRoundingTableValue', Class.new)

    allow(CustomRoundingTableValue).to receive(:find_by)
      .with(custom_rounding_table_id: 3321, label: label)
      .and_return(custom_rounding_table_value)
  end

  def stub_raw_custom_rounding_table(custom_rounding_table)
    stub_const('CustomRoundingTable', Class.new)

    allow(CustomRoundingTable).to receive(:by_year)
      .with(2017)
      .and_return(CustomRoundingTable)

    allow(CustomRoundingTable).to receive(:by_unity)
      .with(unity.id)
      .and_return(CustomRoundingTable)

    allow(CustomRoundingTable).to receive(:by_grade)
      .with([grade.id])
      .and_return(CustomRoundingTable)

    allow(CustomRoundingTable).to receive(:by_avaliation)
      .with(RoundedAvaliations::NUMERICAL_EXAM)
      .and_return(custom_rounding_table)
  end

  def stub_custom_rounding_table
    custom_rounding_table = [double(id: 3321)]

    stub_raw_custom_rounding_table(custom_rounding_table)
  end

  def stub_emtpy_custom_rounding_table
    custom_rounding_table = []

    stub_raw_custom_rounding_table(custom_rounding_table)
  end
end
