# encoding: utf-8
require 'rails_helper'

RSpec.describe TestSetting, type: :model do
  subject { FactoryGirl.build(:test_setting) }

  describe "attributes" do
    it { expect(subject).to respond_to(:year) }
    it { expect(subject).to respond_to(:maximum_score) }
    it { expect(subject).to respond_to(:number_of_decimal_places) }
  end

  describe "associations" do
    it { expect(subject).to have_many(:tests) }
  end

  describe "validations" do
    it { expect(subject).to validate_presence_of(:year) }
    it { expect(subject).to validate_uniqueness_of(:year) }
    it { expect(subject).to validate_numericality_of(:maximum_score).only_integer
                                                                    .is_greater_than_or_equal_to(1)
                                                                    .is_less_than_or_equal_to(1000) }
    it { expect(subject).to validate_numericality_of(:number_of_decimal_places).only_integer
                                                                               .is_greater_than_or_equal_to(0)
                                                                               .is_less_than_or_equal_to(3) }

    context "when fixed tests" do
      before { subject.fix_tests = true }

      it "validates at least one assigned regular test" do
        subject.tests << FactoryGirl.build(:test_setting_test, test_type: 'recovery')

        expect(subject).to_not be_valid
        expect(subject.errors.messages[:tests]).to include('É necessário pelo menos uma avaliação do tipo normal')
      end

      context "when there are assigned regular tests" do
        it "validates regular tests weight equal maximum score" do
          subject.maximum_score = 100
          subject.tests << FactoryGirl.build(:test_setting_test, weight: 10, test_type: 'regular')

          expect(subject).to_not be_valid
          expect(subject.errors.messages[:tests]).to include('A soma dos pesos das avaliações do tipo normal deve resultar no mesmo valor da nota máxima')
        end
      end

      context "when there are assigned recovery tests" do
        it "validates recovery tests weight equal maximum score" do
          subject.maximum_score = 100
          subject.tests << FactoryGirl.build(:test_setting_test, weight: 10, test_type: 'recovery')

          expect(subject).to_not be_valid
          expect(subject.errors.messages[:tests]).to include('A soma dos pesos das avaliações do tipo recuperação deve resultar no mesmo valor da nota máxima')
        end
      end
    end
  end

  describe "default values" do
    before { subject = TestSetting.new }

    it { expect(subject.maximum_score).to eq(10) }
    it { expect(subject.number_of_decimal_places).to eq(2) }
  end
end
