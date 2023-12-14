class StudentRecoveryAverageCalculator
  def initialize(student, classroom, discipline, step)
    @student = student
    @classroom = classroom
    @discipline = discipline
    @step = step
  end

  def recovery_average
    return parallel_recovery_average if recovery_type == RecoveryTypes::PARALLEL

    specific_recovery_average if recovery_type == RecoveryTypes::SPECIFIC
  end

  private

  attr_accessor :student, :classroom, :discipline, :step

  def exam_rule
    classroom.first_exam_rule_with_recovery
  end

  def steps_fetcher
    @steps_fetcher ||= StepsFetcher.new(classroom)
  end

  def recovery_type
    exam_rule.recovery_type
  end

  def parallel_recovery_average
    student.average(
      classroom,
      discipline,
      step
    )
  end

  def specific_recovery_average
    current_recovery_exam_rule = exam_rule.recovery_exam_rules.find { |recovery_exam_rule|
      recovery_exam_rule.steps.include?(step.to_number)
    }

    school_calendar_steps_to_sum = []

    current_recovery_exam_rule.steps.each do |step_number|
      steps_fetcher.steps.each do |step|
        school_calendar_steps_to_sum << step if step.step_number == step_number
      end
    end

    recovery_average_sum = 0

    school_calendar_steps_to_sum.each do |step|
      next unless (average = student.average(classroom, discipline, step))

      recovery_average_sum += average
    end

    recovery_average_sum / school_calendar_steps_to_sum.count
  end
end
