class StudentInRecoverySerializer < StudentSerializer
  attributes :average

  def average
    if exam_rule.recovery_type == RecoveryTypes::PARALLEL
      "%.#{@serialization_options[:number_of_decimal_places]}f" % parallel_recovery_average
    elsif exam_rule.recovery_type == RecoveryTypes::SPECIFIC
      "%.#{@serialization_options[:number_of_decimal_places]}f" % specific_recovery_average
    end
  end

  private

  def exam_rule
    classroom.exam_rule
  end

  def classroom
    @serialization_options[:classroom]
  end

  def school_calendar_step
    @serialization_options[:school_calendar_step]
  end

  def school_calendar
    school_calendar_step.school_calendar
  end

  def parallel_recovery_average
    ParallelRecoveryCalculator.new(student, classroom, discipline, step).recovery
    object.average(
      @serialization_options[:classroom],
      @serialization_options[:discipline],
      @serialization_options[:school_calendar_step]
    )
  end

  def specific_recovery_average
    SpecificRecoveryCalculator.new(student, classroom, discipline, step).recovery

    recovery_exam_rule = exam_rule.recovery_exam_rules.find do |recovery_exam_rule|
      recovery_exam_rule.steps.include? school_calendar_step.to_number
    end

    school_calendar_steps_to_sum = []
    recovery_exam_rule.steps.each do |step|
      school_calendar.steps.each do |school_calendar_step|
        school_calendar_steps_to_sum << school_calendar_step if school_calendar_step.to_number == step
      end
    end

    recovery_average_sum = 0
    recovery_average = 0
    school_calendar_steps_to_sum.each do |school_calendar_step|
      recovery_average_sum += object.average(
        @serialization_options[:classroom],
        @serialization_options[:discipline],
        school_calendar_step
      )
    end

    recovery_average = recovery_average_sum / school_calendar_steps_to_sum.count

    recovery_average
  end
end
