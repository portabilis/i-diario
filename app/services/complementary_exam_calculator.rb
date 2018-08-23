class ComplementaryExamCalculator
  def initialize(affected_score, student_id, discipline_id, classroom_id, step)
    @affected_score = affected_score
    @student_id = student_id
    @discipline_id = discipline_id
    @classroom_id = classroom_id
    @step = step
  end

  def calculate(score)
    return substitution_complementary_exam_score if substitution_complementary_exam_score.present?
    score += sum_substitution_complementary_exam_score

    if substitution_if_greather_complementary_exam_score.present? && substitution_if_greather_complementary_exam_score > score
      substitution_if_greather_complementary_exam_score
    else
      score
    end
  end

  private

  attr_accessor :affected_score, :student_id, :discipline_id, :classroom_id, :step

  def substitution_complementary_exam_score
    @substitution_complementary_exam_score ||= begin
      complementary_exam_students_by_calculation(CalculationTypes::SUBSTITUTION).first.try(:score)
    end
  end

  def substitution_if_greather_complementary_exam_score
    @substitution_if_greather_complementary_exam_score ||= begin
      complementary_exam_students_by_calculation(CalculationTypes::SUBSTITUTION_IF_GREATER).first.try(:score)
    end
  end

  def sum_substitution_complementary_exam_score
    @sum_substitution_complementary_exam_score ||= begin
      complementary_exam_students_by_calculation(CalculationTypes::SUM).sum(:score).to_f
    end
  end

  def complementary_exam_students_by_calculation(calculation)
    ComplementaryExamStudent.by_complementary_exam_id(
      ComplementaryExam.by_classroom_id(classroom_id)
                       .by_discipline_id(discipline_id)
                       .by_date_range(step.start_at, step.end_at)
                       .by_affected_score(affected_score)
                       .by_calculation_type(calculation)
                       .pluck(:id)
    ).by_student_id(student_id)
  end
end
