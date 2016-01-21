def validate_not_in_future_of(attribute)
  ValidateNotInFutureOfMatcher.new(attribute)
end

class ValidateNotInFutureOfMatcher
  def initialize(attribute)
    @attribute = attribute
    @expected_message = I18n.t('errors.messages.not_in_future')
  end

  def matches?(subject)
    @subject = subject

    allow_present_date && allow_past_date && disallow_future_date
  end

  def failure_message
    "Expected errors to include \"#{@expected_message}\" " \
    "when #{@attribute} is in the future"
  end

  def failure_message_when_negated
    "Did not expect errors to include \"#{@expected_message}\" " \
    "when #{@attribute} to in the future"
  end

  def description
    "require #{@attribute} is not be in future"
  end

  private

  def allow_present_date
    @subject.send("#{@attribute}=", Time.zone.today)
    @subject.valid?
    !@subject.errors[@attribute].include?(@expected_message)
  end

  def allow_past_date
    @subject.send("#{@attribute}=", Time.zone.yesterday)
    @subject.valid?
    !@subject.errors[@attribute].include?(@expected_message)
  end

  def disallow_future_date
    @subject.send("#{@attribute}=", Time.zone.tomorrow)
    @subject.valid?
    @subject.errors[@attribute].include?(@expected_message)
  end
end
