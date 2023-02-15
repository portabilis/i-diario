class RecoveryStepsFetcher
  def initialize(step, classroom)
    @step = step
    @classroom = classroom
  end

  def fetch
    steps = []

    if recovery_exam_rule.present?
      steps = steps_fetcher.steps.select { |step|
        recovery_exam_rule.steps.include?(step.to_number)
      }
    end

    steps << @step if steps.empty?

    steps
  end

  private

  def steps_fetcher
    @steps_fetcher ||= StepsFetcher.new(@classroom)
  end

  def recovery_type
    @classroom.first_exam_rule_with_recovery.recovery_type
  end

  def recovery_exam_rule
    @classroom.first_exam_rule_with_recovery.recovery_exam_rules.find do |recovery_diary_record|
      recovery_diary_record.steps.last.eql?(@step.to_number)
    end
  end
end
