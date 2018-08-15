require 'rails_helper'

RSpec.describe ComplementaryExamCalculator, type: :service do
  let(:classroom) { create(:classroom, :current) }
  let(:school_calendar) { create(:current_school_calendar_with_one_step, unity: classroom.unity) }
  let(:complementary_exam_setting) { create(:complementary_exam_setting_with_two_grades) }
  let(:complementary_exam) {
    create(
      :complementary_exam,
      classroom: classroom,
      recorded_at: school_calendar.steps.first.school_day_dates[0],
      step_id: school_calendar.steps.first.id,
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
      expect(subject.calculate(score)).to eq((complementary_exam_student.score + score).to_f)
    end
  end

  context 'exam calculation type is substitution if greater' do
    before do
      complementary_exam_setting.update_attribute(:calculation_type, CalculationTypes::SUBSTITUTION_IF_GREATER)
    end

    context 'score is smaller than parameter' do
      before { complementary_exam_student.update_attribute(:score, score - 0.5) }

      it 'return value passed as parameter' do
        expect(subject.calculate(score)).to eq(score)
      end
    end

    context 'score is greater than parameter' do
      before { complementary_exam_student.update_attribute(:score, score + 0.5) }

      it 'return value passed as parameter' do
        expect(subject.calculate(score)).to eq(complementary_exam_student.score)
      end
    end
  end
end
