class StudentRecoveryAverageCalculator
  def initialize(student, classroom, discipline, step)
    @student = student
    @classroom = classroom
    @discipline = discipline
    @step = step
  end

  def recovery_average
    if recovery_type == RecoveryTypes::PARALLEL
      parallel_recovery_average
    elsif recovery_type == RecoveryTypes::SPECIFIC
      # FIXME Remove this when possible
      if Entity.current.name == 'saomigueldoscampos' || Entity.current.name == 'clientetest3'
        specific_recovery_sum
      else
        specific_recovery_average
      end
    end
  end

  private

  attr_accessor :student, :classroom, :discipline, :step

  def exam_rule
    classroom.exam_rule
  end

  def school_calendar
    step.school_calendar
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

  def specific_recovery_sum
    recovery_exam_rule = exam_rule.recovery_exam_rules.find do |recovery_exam_rule|
      recovery_exam_rule.steps.include? step.to_number
    end

    school_calendar_steps_to_sum = []
    recovery_exam_rule.steps.each do |step|
      school_calendar.steps.each do |school_calendar_step|
        school_calendar_steps_to_sum << school_calendar_step if school_calendar_step.to_number == step
      end
    end

    recovery_average_sum = 0
    school_calendar_steps_to_sum.each do |school_calendar_step|
      recovery_average_sum += student.average(
        classroom,
        discipline,
        school_calendar_step
      )
    end

    recovery_average_sum
  end

  def specific_recovery_average
    recovery_exam_rule = exam_rule.recovery_exam_rules.find do |recovery_exam_rule|
      recovery_exam_rule.steps.include? step.to_number
    end

    school_calendar_steps_to_sum = []
    recovery_exam_rule.steps.each do |step|
      school_calendar.steps.each do |school_calendar_step|
        school_calendar_steps_to_sum << school_calendar_step if school_calendar_step.to_number == step
      end
    end

    recovery_average_sum = 0
    school_calendar_steps_to_sum.each do |school_calendar_step|
      recovery_average_sum += student.average(
        classroom,
        discipline,
        school_calendar_step
      )
    end

    recovery_average = recovery_average_sum / school_calendar_steps_to_sum.count

    recovery_average
  end
end
