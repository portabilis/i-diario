require 'spec_helper_lite'
require 'enumerate_it'

require 'app/services/score_rounder'
require 'app/enumerations/rounding_table_action'

RSpec.describe ScoreRounder, type: :service do
  let(:exam_rule) { double(:exam_rule) }
  let(:rounding_table) { double(:rounding_table) }
  let(:rounding_table_value) { double(:rounding_table_value) }
  let(:rounding_table_values) { [rounding_table_value] }
  let(:exact_decimal_place) { "" }
  let(:label) { "0" }
  let(:action) { RoundingTableAction::NONE }

  subject do
    ScoreRounder.new(exam_rule)
  end

  before do
    stub_exam_rule
    stub_rounding_table
    stub_rounding_table_value
  end

  describe '#round' do
    context 'when there is no rounding action' do
      let(:label) { "5" }
      let(:action) { RoundingTableAction::NONE }
      it "should return the same score truncated" do
        expect(subject.round(8.555)).to be(8.555)
      end
    end

    context 'when rounding is below' do
      let(:label) { "9" }
      let(:action) { RoundingTableAction::BELOW }
      it "should round to below" do
        expect(subject.round(5.9)).to be(5.0)
      end
    end

    context 'when rounding is above' do
      let(:label) { "3" }
      let(:action) { RoundingTableAction::ABOVE }
      it "should round to above" do
        expect(subject.round(3.3)).to be(4.0)
      end
    end

    context 'when rounding is specific' do
      let(:label) { "9" }
      let(:action) { RoundingTableAction::SPECIFIC }
      let(:exact_decimal_place) { 5 }
      it "should round to .5" do
        expect(subject.round(2.9)).to be(2.5)
      end
    end

    context 'when number is complex' do
      let(:label) { "4" }
      let(:action) { RoundingTableAction::ABOVE }
      it "it should round to above normally" do
        expect(subject.round(2.44443)).to be(3.0)
      end
    end

    context 'when number is zero' do
      let(:label) { "0" }
      context 'and there is no rounding action' do
        let(:action) { RoundingTableAction::NONE }
        it "it should return zero" do
          expect(subject.round(0.0)).to be(0.0)
        end
      end
      context 'when number is 10.0' do
        let(:action) { RoundingTableAction::ABOVE }
        it "should not round at all" do
          expect(subject.round(10.0)).to be(10.0)
        end
      end
    end

  end

  def stub_exam_rule
    allow(exam_rule).to receive(:rounding_table).and_return(rounding_table)
  end

  def stub_rounding_table
    allow(rounding_table).to receive(:values).and_return(rounding_table_values)
  end

  def stub_rounding_table_value
    allow(rounding_table_value).to receive(:label).and_return(label)
    allow(rounding_table_value).to receive(:action).and_return(action)
    allow(rounding_table_value).to receive(:exact_decimal_place).and_return(exact_decimal_place)
  end
end
