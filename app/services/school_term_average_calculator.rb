class SchoolTermAverageCalculator
  def initialize(classroom)
    @classroom = classroom
  end

  def calculate(average, recovery_score)
    return calculate_sum(average, recovery_score) if calculate_sum?
    return average if recovery_score.nil? || recovery_score <= 0
    return recovery_score if average.nil?
    return calculate_average(average, recovery_score) if calculate_average?

    recovery_score > average ? recovery_score : average
  end

  private

  attr_accessor :classroom

  def calculate_sum(average, recovery_score)
    (recovery_score.presence || average).to_f + average.to_f
  end

  def calculate_average(average, recovery_score)
    new_average = (recovery_score.to_f + average.to_f) / 2
    new_average > average ? new_average : average
  end

  def calculate_average?
    classroom.first_exam_rule.try(:calculate_school_term_average?)
  end

  def calculate_sum?
    classroom.first_exam_rule.try(:calculate_school_term_sum?)
  end
end
