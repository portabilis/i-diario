require 'rails_helper'

RSpec.describe ComplementaryExamCalculator, type: :service do
  let(:classroom) {
    create(
      :classroom,
      :with_classroom_semester_steps
    )
  }
  let(:step) { classroom.calendar.classroom_steps.first }
  let(:complementary_exam_setting) do
    create(:complementary_exam_setting, :with_two_grades, :with_teacher_discipline_classroom)
  end
  let(:complementary_exam) {
    create(
      :complementary_exam,
      :with_teacher_discipline_classroom,
      classroom: classroom,
      recorded_at: Date.current,
      step_id: step.id,
      complementary_exam_setting: complementary_exam_setting
    )
  }
  let(:complementary_exam_student) { create(:complementary_exam_student, complementary_exam: complementary_exam) }
  let(:score) { rand(0.0..100.0).round(5) }

  subject do
    described_class.new(
      complementary_exam_setting.affected_score,
      complementary_exam_student.student,
      complementary_exam.discipline_id,
      complementary_exam.classroom_id,
      complementary_exam.step
    )
  end

  context 'exam calculation type is substitution' do
    before do
      complementary_exam_setting.update_attribute(:calculation_type, CalculationTypes::SUBSTITUTION)
    end

    it 'return complementary_exam score' do
      expect(subject.calculate(score)).to eq(complementary_exam_student.score)
    end
  end

  context 'exam calculation type is sum' do
    before do
      complementary_exam_setting.update_attribute(:calculation_type, CalculationTypes::SUM)
    end

    it 'return complementary_exam score plus value passed as parameter' do
      test_setting = TestSetting.find_by(year: classroom.year)
      test_setting.update(maximum_score: 100)
      expect(subject.calculate(score).round(4)).to eq((complementary_exam_student.score + score).to_f.round(4))
    end

    context 'calculation exceeds test setting maximum score' do
      it 'returns test setting maximum score' do
        score = 110
        test_setting = TestSetting.find_by(year: classroom.year)
        test_setting.update(maximum_score: score)
        expect(subject.calculate(score)).to eq(test_setting.maximum_score.to_f)
      end
    end
  end

  context 'exam calculation type is substitution if greater' do
    before do
      complementary_exam_setting.update_attribute(:calculation_type, CalculationTypes::SUBSTITUTION_IF_GREATER)
    end

    context 'score is smaller than parameter' do
      before { complementary_exam_student.update_attribute(:score, score - 0.5) }

      it 'return value passed as parameter' do
        test_setting = TestSetting.find_by(year: classroom.year)
        test_setting.update(maximum_score: 100)
        expect(subject.calculate(score)).to eq(score)
      end
    end

    context 'score is greater than parameter' do
      before { complementary_exam_student.update_attribute(:score, score + 0.5) }

      it 'return value passed as parameter' do
        test_setting = TestSetting.find_by(year: classroom.year)
        test_setting.update(maximum_score: 100)
        expect(subject.calculate(score)).to eq(complementary_exam_student.score)
      end
    end
  end

  context 'integral calculation type' do
    context 'when there are no integral exams' do
      it 'returns same value passed as parameter' do
        expect(subject.send(:calculate_integral, score)).to eq(score)
      end
    end

    context 'when there are integral exams' do
      before do
        complementary_exam_setting.update_attribute(:calculation_type, CalculationTypes::INTEGRAL)
      end

      it 'returns score + integral exams scores divided by 2' do
        integral_score = subject.send(:exams_by_calculation, CalculationTypes::INTEGRAL).sum(:score).to_f
        expect(subject.send(:calculate_integral, score)).to eq((score + integral_score) / 2)
      end
    end
  end
end
