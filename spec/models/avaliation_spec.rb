# encoding: utf-8

require 'rails_helper'

RSpec.describe Avaliation, type: :model do
  describe "associations" do
    it { expect(subject).to belong_to(:unity) }
    it { expect(subject).to belong_to(:classroom) }
    it { expect(subject).to belong_to(:discipline) }
    it { expect(subject).to belong_to(:school_calendar) }
    it { expect(subject).to belong_to(:test_setting) }
    it { expect(subject).to belong_to(:test_setting_test) }
  end

  describe "validations" do
    it { expect(subject).to validate_presence_of(:unity) }
    it { expect(subject).to validate_presence_of(:classroom) }
    it { expect(subject).to validate_presence_of(:discipline) }
    it { expect(subject).to validate_presence_of(:school_calendar) }
    it { expect(subject).to validate_presence_of(:test_setting) }
    it { expect(subject).to validate_presence_of(:test_date) }
    it { expect(subject).to validate_presence_of(:class_number) }

    context "when classroom present" do
      let(:exam_rule_with_concept_score_type) { build(:exam_rule, score_type: ScoreTypes::CONCEPT) }
      let(:classroom_with_concept_score_type) { build(:classroom, exam_rule: exam_rule_with_concept_score_type) }
      subject { build(:avaliation, classroom: classroom_with_concept_score_type) }

      it "validates that classroom score type is numeric" do
        expect(subject).to_not be_valid
        expect(subject.errors.messages[:classroom]).to include('o tipo de nota da regra de avaliação não é numérica')
      end
    end

    context "when configuration fix tests" do
      before do
        subject.test_setting = TestSetting.new(fix_tests: true)
        subject.school_calendar = SchoolCalendar.first
      end

      it { expect(subject).to validate_presence_of(:test_setting_test) }
    end

    context "when configuration not fix tests" do
      before do
        subject.test_setting = TestSetting.new(fix_tests: false)
        subject.school_calendar = SchoolCalendar.first
      end

      it { expect(subject).to validate_presence_of(:description) }
    end
  end
end
