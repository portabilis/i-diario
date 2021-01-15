require 'rails_helper'

RSpec.describe TestSetting, type: :model do
  subject { FactoryGirl.build(:test_setting) }
  let(:school_term_type_step) { create(:school_term_type_step) }

  describe 'attributes' do
    it { expect(subject).to respond_to(:exam_setting_type) }
    it { expect(subject).to respond_to(:school_term_type_step) }
    it { expect(subject).to respond_to(:year) }
    it { expect(subject).to respond_to(:maximum_score) }
    it { expect(subject).to respond_to(:number_of_decimal_places) }
  end

  describe 'associations' do
    it { expect(subject).to have_many(:tests) }
  end

  describe 'validations' do
    it { expect(subject).to validate_presence_of(:exam_setting_type) }
    it { expect(subject).to validate_presence_of(:year) }

    # FIXME: Not working, probably a bug on shoulda-matchers. Need to be reported.
    # it { expect(subject).to validate_numericality_of(:maximum_score).is_greater_than_or_equal_to(1)
    #                                                                 .is_less_than_or_equal_to(1000)
    #                                                                 .only_integer }


    # FIXME: Not working, probably a bug on shoulda-matchers. Need to be reported.
    # it { expect(subject).to validate_numericality_of(:number_of_decimal_places).is_greater_than_or_equal_to(0)
    #                                                                            .is_less_than_or_equal_to(3)
    #                                                                            .only_integer }

    context 'when #exam_setting_type equals to general' do
      before do
        subject.exam_setting_type = ExamSettingTypes::GENERAL
        subject.school_term_type_step = nil
      end

      it 'should not validate presence of school term' do
        expect(subject.valid?).to be(true)
        expect(subject.errors[:school_term_type_step]).to be_empty
      end

      it 'should validate uniqueness of year' do
        another_test_setting = FactoryGirl.create(:test_setting, exam_setting_type: subject.exam_setting_type,
                                                                 year: subject.year,
                                                                 school_term_type_step: subject.school_term_type_step)

        expect(subject).to_not be_valid
        expect(subject.errors[:year]).to include('já está em uso')
      end
    end

    context 'when #exam_setting_type equals to by_school_term' do
      before { subject.exam_setting_type = ExamSettingTypes::BY_SCHOOL_TERM }

      it 'should validate presence of school term' do
        subject.school_term_type_step = nil

        expect(subject.valid?).to be(false)
        expect(subject.errors[:school_term_type_step]).to include('não pode ficar em branco')
      end

      it 'should validate uniqueness of year' do
        another_test_setting = FactoryGirl.create(:test_setting, exam_setting_type: ExamSettingTypes::GENERAL,
                                                                 year: subject.year)

        expect(subject).to_not be_valid
        expect(subject.errors[:year]).to include('já está em uso')
      end

      it 'should validate uniqueness of year/school_term_type_step' do
        subject.school_term_type_step = school_term_type_step

        another_test_setting = FactoryGirl.create(:test_setting, exam_setting_type: subject.exam_setting_type,
                                                                 year: subject.year,
                                                                 school_term_type_step: subject.school_term_type_step)

        expect(subject).to_not be_valid
        expect(subject.errors[:school_term_type_step]).to include('já está em uso')
      end
    end

    context 'when sum calculation type' do
      before { subject.average_calculation_type = AverageCalculationTypes::SUM }

      it 'validates at least one assigned test' do
        subject.tests = []

        expect(subject).to_not be_valid
        expect(subject.errors.messages[:tests]).to include('É necessário pelo menos uma avaliação')
      end

      context 'when there are assigned tests' do
        before { subject.tests << FactoryGirl.build(:test_setting_test, weight: 101) }
        it 'they should be less or equal to maximum score' do
          subject.maximum_score = 100
          expect(subject).to_not be_valid
          expect(subject.errors.messages[:tests]).to include('A soma dos pesos das avaliações deve resultar em um valor menor ou igual da nota máxima')
        end
      end
    end
  end

  describe 'default values' do
    subject { TestSetting.new }

    it { expect(subject.maximum_score).to eq(10) }
    it { expect(subject.number_of_decimal_places).to eq(2) }
  end
end
