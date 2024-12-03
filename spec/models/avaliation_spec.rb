require 'rails_helper'

RSpec.describe Avaliation, type: :model do
  let(:classroom) { create(:classroom, :with_classroom_semester_steps) }
  let(:step) { classroom.calendar.classroom_steps.first }

  subject do
    build(
      :avaliation,
      :with_teacher_discipline_classroom
    )
  end

  describe 'attributes' do
    it { expect(subject).to respond_to(:weight) }
    it { expect(subject).to respond_to(:observations) }
  end

  describe 'associations' do
    it { expect(subject).to belong_to(:classroom) }
    it { expect(subject).to belong_to(:discipline) }
    it { expect(subject).to belong_to(:school_calendar) }
    it { expect(subject).to belong_to(:test_setting) }
    it { expect(subject).to belong_to(:test_setting_test) }
  end

  describe 'validations' do
    it { expect(subject).to validate_presence_of(:classroom) }
    it { expect(subject).to validate_presence_of(:discipline) }
    it { expect(subject).to validate_presence_of(:school_calendar) }
    it {
      allow_any_instance_of(Avaliation).to receive(:grades_belongs_to_test_setting).and_return(true)

      expect(subject).to validate_presence_of(:test_setting)
    }
    it { expect(subject).to validate_presence_of(:test_date) }
    it { expect(subject).to validate_school_calendar_day_of(:test_date) }

    context 'when classroom present' do
      let(:exam_rule) { create(:exam_rule, score_type: ScoreTypes::CONCEPT) }
      let(:classroom_with_concept_score_type) { build(:classroom, :score_type_concept, exam_rule: exam_rule) }

      subject do
        build(
          :avaliation,
          :with_teacher_discipline_classroom,
          classroom: classroom_with_concept_score_type
        )
      end

      it 'should validate that classroom score type is numeric' do
        expect(subject).to_not be_valid
        expect(subject.errors.messages[:classroom]).to include('o tipo de nota da regra de avaliação não é numérica')
      end
    end

    context 'when configuration with sum calculation type' do
      let(:test_setting_with_sum_calculation_type) { create(:test_setting_with_sum_calculation_type) }

      subject do
        build(
          :avaliation,
          :with_teacher_discipline_classroom,
          classroom: classroom,
          test_date: Date.current,
          test_setting: test_setting_with_sum_calculation_type
        )
      end

      it { expect(subject).to validate_presence_of(:test_setting_test) }

      it 'should validate that test_setting_test is unique per step/classroom/discipline' do
        another_avaliation = create(
          :avaliation,
          test_date: subject.test_date,
          discipline: subject.discipline,
          classroom: subject.classroom,
          test_setting: subject.test_setting,
          test_setting_test: subject.test_setting.tests.first,
          grade_ids: subject.grade_ids,
          teacher_id: subject.teacher_id
        )
        subject.test_setting_test = another_avaliation.test_setting_test

        expect(subject).to_not be_valid
        expect(subject.errors[:test_setting_test]).to include('deve ser única por etapa')
      end
    end

    context 'when configuration with sum calculation type that allow break up' do
      let(:test_setting_with_sum_calculation_type_that_allow_break_up) {
        create(:test_setting_with_sum_calculation_type_that_allow_break_up)
      }

      subject do
        build(
          :avaliation,
          :with_teacher_discipline_classroom,
          classroom: classroom,
          test_date: Date.current,
          test_setting: test_setting_with_sum_calculation_type_that_allow_break_up,
          test_setting_test: test_setting_with_sum_calculation_type_that_allow_break_up.tests.first
        )
      end

      it { expect(subject).to validate_presence_of(:description) }
      it { expect(subject).to validate_presence_of(:weight) }

      it 'should not validate that test_setting_test is unique per step/classroom/discipline' do
        another_avaliation = create(
          :avaliation,
          classroom: subject.classroom,
          discipline: subject.discipline,
          test_date: subject.test_date + 1,
          test_setting: subject.test_setting,
          test_setting_test: subject.test_setting.tests.first,
          teacher_id: subject.teacher_id,
          weight: 5
        )
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
        another_avaliation = create(
          :avaliation,
          classroom: subject.classroom,
          discipline: subject.discipline,
          test_date: subject.test_date,
          test_setting: subject.test_setting,
          test_setting_test: subject.test_setting.tests.first,
          teacher_id: subject.teacher_id,
          grade_ids: subject.grade_ids,
          weight: subject.test_setting.tests.first.weight / 2
        )
        subject.test_setting_test = another_avaliation.test_setting_test
        subject.weight = another_avaliation.weight * 2

        expect(subject).to_not be_valid
        expect(subject.errors[:weight]).to include("deve ser menor ou igual a #{subject.test_setting_test.weight - another_avaliation.weight}")
      end

      it 'should validate that test_setting_test is still available' do
        another_avaliation = create(
          :avaliation,
          classroom: subject.classroom,
          discipline: subject.discipline,
          test_date: subject.test_date,
          test_setting: subject.test_setting,
          test_setting_test: subject.test_setting.tests.first,
          teacher_id: subject.teacher_id,
          grade_ids: subject.grade_ids,
          weight: subject.test_setting.tests.first.weight
        )
        subject.test_setting_test = another_avaliation.test_setting_test
        subject.weight = another_avaliation.weight

        expect(subject).to_not be_valid
        expect(subject.errors[:test_setting_test]).to include('já foram criadas avaliações que atingiram o peso limite para este tipo de avaliação')
        expect(subject.errors[:weight].any?).to be(false)
      end
    end

    context 'when configuration with arithmetic calculation type' do
      let(:test_setting_with_arithmetic_calculation_type) {
        create(:test_setting, average_calculation_type: AverageCalculationTypes::ARITHMETIC)
      }

      subject do
        build(
          :avaliation,
          :with_teacher_discipline_classroom,
          test_setting: test_setting_with_arithmetic_calculation_type
        )
      end

      it { expect(subject).to validate_presence_of(:description) }
    end
  end
end
