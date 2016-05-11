def validate_school_calendar_day_of(attribute)
  ValidateSchoolCalendarDayOfMatcher.new(attribute)
end

class ValidateSchoolCalendarDayOfMatcher
  def initialize(attribute)
    @attribute = attribute
    @expected_message = I18n.t('errors.messages.not_school_calendar_day')
  end

  def matches?(subject)
    @subject = subject

    allow_day_in_school_calendar && disallow_day_not_in_school_calendar
  end

  def failure_message
    "Expected errors to include \"#{@expected_message}\" " \
    "when #{@attribute} is not a school calendar day"
  end

  def failure_message_when_negated
    "Did not expect errors to include \"#{@expected_message}\" " \
    "when #{@attribute} is not a school calendar day"
  end

  def description
    "require #{@attribute} to be a school calendar day"
  end

  private

  def allow_day_in_school_calendar
    school_calendar = FactoryGirl.create(:school_calendar_with_one_step)
    @subject.school_calendar = school_calendar if @subject.respond_to?(:school_calendar=)
    @subject.send("#{@attribute}=", school_calendar.steps.first.end_at)

    @subject.valid?

    !@subject.errors[@attribute].include?(@expected_message)
  end

  def disallow_day_not_in_school_calendar
    school_calendar = FactoryGirl.create(:school_calendar_with_one_step)
    @subject.school_calendar = school_calendar if @subject.respond_to?(:school_calendar=)
    @subject.send("#{@attribute}=", school_calendar.steps.first.end_at + 1.day)

    @subject.valid?

    @subject.errors[@attribute].include?(@expected_message)
  end
end
