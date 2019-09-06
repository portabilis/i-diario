def validate_school_term_day_of(attribute)
  ValidateSchoolTermDayOfMatcher.new(attribute)
end

class ValidateSchoolTermDayOfMatcher
  def initialize(attribute)
    @attribute = attribute
    @expected_message = I18n.t('errors.messages.not_school_term_day')
  end

  def matches?(subject)
    @subject = subject

    allow_day_in_school_term && disallow_day_not_in_school_term
  end

  def failure_message
    "Expected errors to include \"#{@expected_message}\" " \
    "when #{@attribute} is not a school term day"
  end

  def failure_message_when_negated
    "Did not expect errors to include \"#{@expected_message}\" " \
    "when #{@attribute} is not a school term day"
  end

  def description
    "require #{@attribute} to be a school term day"
  end

  private

  def allow_day_in_school_term
    step = @subject.classroom.calendar.classroom_steps.first
    @subject.step_id = step.id
    @subject.send("#{@attribute}=", step.end_at)

    @subject.valid?

    !@subject.errors[@attribute].include?(@expected_message)
  end

  def disallow_day_not_in_school_term
    step = @subject.classroom.calendar.classroom_steps.first
    @subject.step_id = step.id
    @subject.send("#{@attribute}=", step.end_at + 1.day)

    @subject.valid?

    @subject.errors[@attribute].include?(@expected_message)
  end
end
