class RecoveryStepsFetcher
  def initialize(step, classroom)
    @step = step
    @classroom = classroom
  end

  def fetch
    steps = []

    if recovery_exam_rule.present?
      steps = @step.school_calendar.steps.select do |step|
        recovery_exam_rule.steps.include?(step.to_number)
      end
    end

    steps << @step if steps.empty?

    steps
  end

  private

  def recovery_type
    @classroom.exam_rule.recovery_type
  end

  def recovery_exam_rule
    @classroom.exam_rule.recovery_exam_rules.find do |recovery_diary_record|
      recovery_diary_record.steps.last.eql?(@step.to_number)
    end
  end
end
