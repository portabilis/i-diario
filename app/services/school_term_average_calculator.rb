class SchoolTermAverageCalculator
  def initialize(classroom)
    @classroom = classroom
  end

  def calculate(average, recovery_score)
    return average unless recovery_score > 0

    if calculate_average?
      (recovery_score.to_f + average.to_f) / 2
    else
      recovery_score > average ? recovery_score : average
    end
  end

  private

  attr_accessor :classroom

  def calculate_average?
    classroom.exam_rule.try(:calculate_school_term_average?)
  end
end
