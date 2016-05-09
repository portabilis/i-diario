require 'rails_helper'

RSpec.describe Avaliation, type: :model do
  let(:school_calendar) { SchoolCalendar.find_by_year(2015) }
  subject { FactoryGirl.build(:avaliation) }

  describe 'attributes' do
    it { expect(subject).to respond_to(:weight) }
    it { expect(subject).to respond_to(:classes) }
    it { expect(subject).to respond_to(:observations) }
  end

  describe 'associations' do
    it { expect(subject).to belong_to(:unity) }
    it { expect(subject).to belong_to(:classroom) }
    it { expect(subject).to belong_to(:discipline) }
    it { expect(subject).to belong_to(:school_calendar) }
    it { expect(subject).to belong_to(:test_setting) }
    it { expect(subject).to belong_to(:test_setting_test) }
  end

  describe 'validations' do
    it { expect(subject).to validate_presence_of(:unity) }
    it { expect(subject).to validate_presence_of(:classroom) }
    it { expect(subject).to validate_presence_of(:discipline) }
    it { expect(subject).to validate_presence_of(:school_calendar) }
    it { expect(subject).to validate_presence_of(:test_setting) }
    it { expect(subject).to validate_presence_of(:test_date) }
    it { expect(subject).to validate_school_calendar_day_of(:test_date) }

    context 'when classroom present' do
      let(:exam_rule_with_concept_score_type) { FactoryGirl.build(:exam_rule, score_type: ScoreTypes::CONCEPT) }
      let(:classroom_with_concept_score_type) { FactoryGirl.build(:classroom, exam_rule: exam_rule_with_concept_score_type) }
      subject { FactoryGirl.build(:avaliation, classroom: classroom_with_concept_score_type) }

      it 'should validate that classroom score type is numeric' do
        expect(subject).to_not be_valid
        expect(subject.errors.messages[:classroom]).to include('o tipo de nota da regra de avaliação não é numérica')
      end
    end

    context 'when there is already an avaliation with the classroom/discipline/test_date and class number' do
      let(:another_avaliation) { create(:avaliation, test_date: '03/02/2015',
                                                     classes: '1',
                                                     school_calendar: school_calendar) }
      subject { build(:avaliation, unity: another_avaliation.unity,
                                   classroom: another_avaliation.classroom,
                                   discipline: another_avaliation.discipline,
                                   test_date: another_avaliation.test_date,
                                   classes: '1',
                                   school_calendar: another_avaliation.school_calendar) }

      it 'should not be valid' do
        expect(subject).to_not be_valid
        expect(subject.errors[:classes]).to include('já existe uma avaliação para a aula informada')
      end
    end

    context 'when configuration with fixed tests' do
      let(:test_setting_with_fixed_tests) { FactoryGirl.create(:test_setting_with_fixed_tests) }
      subject { FactoryGirl.build(:avaliation, test_date: '03/02/2015',
                                               school_calendar: school_calendar,
                                               test_setting: test_setting_with_fixed_tests) }

      it { expect(subject).to validate_presence_of(:test_setting_test) }

      it 'should validate that test_setting_test is unique per step/classroom/discipline' do
        another_avaliation = FactoryGirl.create(:avaliation, test_date: '03/02/2015',
                                                             school_calendar: school_calendar,
                                                             discipline: subject.discipline,
                                                             classroom: subject.classroom,
                                                             test_setting: subject.test_setting,
                                                             test_setting_test: subject.test_setting.tests.first)
        subject.test_setting_test = another_avaliation.test_setting_test

        expect(subject).to_not be_valid
        expect(subject.errors[:test_setting_test]).to include('deve ser única por etapa')
      end
    end

    context 'when configuration with fixed tests that allow break up' do
      let(:test_setting_with_fixed_tests_that_allow_break_up) { FactoryGirl.create(:test_setting_with_fixed_tests_that_allow_break_up) }
      subject { FactoryGirl.build(:avaliation, school_calendar: school_calendar,
                                               test_date: '03/02/2015',
                                               test_setting: test_setting_with_fixed_tests_that_allow_break_up,
                                               test_setting_test: test_setting_with_fixed_tests_that_allow_break_up.tests.first) }

      it { expect(subject).to validate_presence_of(:description) }
      it { expect(subject).to validate_presence_of(:weight) }

      it 'should not validate that test_setting_test is unique per step/classroom/discipline' do
        another_avaliation = FactoryGirl.create(:avaliation, school_calendar: school_calendar,
                                                             classroom: subject.classroom,
                                                             discipline: subject.discipline,
                                                             test_date: '04/02/2015',
                                                             test_setting: subject.test_setting,
                                                             test_setting_test: subject.test_setting.tests.first,
                                                             weight: 5)
        subject.weight = 5
        subject.test_setting_test = another_avaliation.test_setting_test

        expect(subject).to be_valid
        expect(subject.errors[:test_setting_test].any?).to be(false)
      end

      it 'should validate that weight is less than or equal to test_setting_test.weight' do
        subject.weight = subject.test_setting_test.weight + 1

        expect(subject).to_not be_valid
        expect(subject.errors[:weight]).to include("deve ser menor ou igual a #{subject.test_setting_test.weight}")
      end

      it 'should validate that weight plus the weight of other avaliations with same test_setting_test is less than or equal to test_setting_test.weight' do
        another_avaliation = FactoryGirl.create(:avaliation, school_calendar: school_calendar,
                                                             classroom: subject.classroom,
                                                             discipline: subject.discipline,
                                                             test_date: '03/02/2015',
                                                             test_setting: subject.test_setting,
                                                             test_setting_test: subject.test_setting.tests.first,
                                                             weight: subject.test_setting.tests.first.weight / 2)
        subject.test_setting_test = another_avaliation.test_setting_test
        subject.weight = another_avaliation.weight * 2

        expect(subject).to_not be_valid
        expect(subject.errors[:weight]).to include("deve ser menor ou igual a #{subject.test_setting_test.weight - another_avaliation.weight}")
      end

      it 'should validate that test_setting_test is still available' do
        another_avaliation = FactoryGirl.create(:avaliation, school_calendar: school_calendar,
                                                             classroom: subject.classroom,
                                                             discipline: subject.discipline,
                                                             test_date: '03/02/2015',
                                                             test_setting: subject.test_setting,
                                                             test_setting_test: subject.test_setting.tests.first,
                                                             weight: subject.test_setting.tests.first.weight)
        subject.test_setting_test = another_avaliation.test_setting_test
        subject.weight = another_avaliation.weight

        expect(subject).to_not be_valid
        expect(subject.errors[:test_setting_test]).to include('já foram criadas avaliações que atingiram o peso limite para este tipo de avaliação')
        expect(subject.errors[:weight].any?).to be(false)
      end
    end

    context 'when configuration with not fixed tests' do
      let(:test_setting_with_not_fixed_tests) { FactoryGirl.create(:test_setting, fix_tests: false) }
      subject { FactoryGirl.build(:avaliation, test_setting: test_setting_with_not_fixed_tests) }

      it { expect(subject).to validate_presence_of(:description) }
    end
  end
end
