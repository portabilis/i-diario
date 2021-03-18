class ComplementaryExamCalculator
  def initialize(affected_score, student_id, discipline_id, classroom_id, step)
    @affected_score = affected_score
    @student_id = student_id
    @discipline_id = discipline_id
    @classroom_id = classroom_id
    @step = step
  end

  def calculate(score)
    score = make_calculations(score)
    calculate_integral(maximum_score && maximum_score < score ? maximum_score : score)
  end

  private

  def calculate_integral(score)
    integral_score = exams_by_calculation(CalculationTypes::INTEGRAL)

    return score if integral_score.blank?

    ((score + integral_score.sum(:score).to_f) / 2)
  end

  def maximum_score
    @maximum_score ||= test_setting.try(:maximum_score)
  end

  def test_setting
    classroom = Classroom.find_by(id: classroom_id)

    return if classroom.blank?

    @test_setting = TestSettingFetcher.current(classroom, @step)
  end

  def make_calculations(score)
    return substitution_score if substitution_score.present?
    score += sum_substitution_score

    if substitution_if_greather_score.present? && substitution_if_greather_score > score
      substitution_if_greather_score
    else
      score
    end
  end

  attr_accessor :affected_score, :student_id, :discipline_id, :classroom_id, :step

  def substitution_score
    @substitution_score ||= exams_by_calculation(CalculationTypes::SUBSTITUTION).first.try(:score)
  end

  def substitution_if_greather_score
    @substitution_if_greather_score ||=
      exams_by_calculation(CalculationTypes::SUBSTITUTION_IF_GREATER).first.try(:score)
  end

  def sum_substitution_score
    @sum_substitution_score ||= exams_by_calculation(CalculationTypes::SUM).sum(:score).to_f
  end

  def exams_by_calculation(calculation)
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
