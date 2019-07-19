require 'rails_helper'

RSpec.describe SchoolTermAverageCalculator, type: :service do
  let(:classroom) { create(:classroom, :current) }

  subject do
    described_class.new(
      classroom
    )
  end

  context 'should calculate average' do
    before do
      classroom.exam_rule.calculate_avg_parallel_exams = true
    end

    it 'returns average of parameters' do
      expect(subject.calculate(4, 6)).to eq(5)
      expect(subject.calculate(6, 6)).to eq(6)
      expect(subject.calculate(1, 2)).to eq(1.5)
    end
  end

  context 'should calculate greater score' do
    before do
      classroom.exam_rule.calculate_avg_parallel_exams = false
    end

    it 'returns greater parameter passed' do
      greater_score = 4
      lower_score = 2

      expect(subject.calculate(lower_score,greater_score)).to eq(greater_score)
      expect(subject.calculate(greater_score,lower_score)).to eq(greater_score)
      expect(subject.calculate(greater_score,greater_score)).to eq(greater_score)
    end
  end
end
