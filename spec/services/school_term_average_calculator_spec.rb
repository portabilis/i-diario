require 'rails_helper'

RSpec.describe SchoolTermAverageCalculator, type: :service do
  let(:classrooms_grade) { create(:classrooms_grade) }

  subject do
    described_class.new(
      classrooms_grade.classroom
    )
  end

  context 'calculation type is average' do
    before do
      classrooms_grade.exam_rule.parallel_exams_calculation_type = ParallelExamsCalculationTypes::AVERAGE
    end

    context 'recovery_score is a number' do
      it 'returns average of parameters if greater than first' do
        expect(subject.calculate(4, 6)).to eq(6)
        expect(subject.calculate(6, 6)).to eq(6)
        expect(subject.calculate(1, 2)).to eq(2)
        expect(subject.calculate(2, 1)).to eq(2)
        expect(subject.calculate(6, 0)).to eq(6)
      end
    end

    context 'recovery_score is nil' do
      it 'returns first parameter' do
        expect(subject.calculate(6, nil)).to eq(6)
      end
    end
  end

  context 'calculation type is sum' do
    before do
      classrooms_grade.exam_rule.parallel_exams_calculation_type = ParallelExamsCalculationTypes::SUM
    end

    context 'recovery_score is a number' do
      it 'returns sum of parameters' do
        expect(subject.calculate(5, 9)).to eq(9)
        expect(subject.calculate(6, 0)).to eq(6)
      end
    end

    context 'recovery_score is nil' do
      it 'returns first parameter' do
        expect(subject.calculate(6, nil)).to eq(6)
      end
    end
  end

  context 'calculation type is substitution' do
    before do
      classrooms_grade.exam_rule.parallel_exams_calculation_type = ParallelExamsCalculationTypes::SUBSTITUTION
    end

    context 'recovery_score is a number' do
      it 'returns greater parameter passed' do
        greater_score = 4
        lower_score = 2

        expect(subject.calculate(lower_score, greater_score)).to eq(greater_score)
        expect(subject.calculate(greater_score, lower_score)).to eq(greater_score)
        expect(subject.calculate(greater_score, greater_score)).to eq(greater_score)
      end
    end

    context 'recovery_score is nil' do
      it 'returns first parameter' do
        expect(subject.calculate(6, nil)).to eq(6)
      end
    end
  end
end
