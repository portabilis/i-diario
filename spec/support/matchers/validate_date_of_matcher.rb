def validate_date_of(attribute)
  ValidateDateOfMatcher.new(attribute)
end

class ValidateDateOfMatcher
  def initialize(attribute)
    @attribute = attribute
    @expected_message = I18n.t('errors.messages.invalid_date')
    @comparisons = {}
    @descriptions = ['a valid date']
    @failure_message_description = 'a valid date'
  end

  def matches?(subject)
    @subject = subject

    allow_valid_dates &&
      allow_valid_string_dates &&
        disallow_invalid_dates &&
          do_validate_is_not_in_future &&
            do_comparisons
  end

  def failure_message
    "Expected errors to include \"#{@expected_message}\" " \
    "when #{@attribute} is #{@failure_message_description}"
  end

  def failure_message_when_negated
    "Did not expect errors to include \"#{@expected_message}\" " \
    "when #{@attribute} is #{@failure_message_description}"
  end

  def description
    "require #{@attribute} to be #{@descriptions.join(', ')}"
  end

  def is_not_in_future
    @validate_is_not_in_future = true
    self
  end

  def is_greater_than(value)
    @comparisons[:is_greater_than] = value
    self
  end

  def is_greater_than_or_equal_to(value)
    @comparisons[:is_greater_than_or_equal_to] = value
    self
  end

  def is_equal_to(value)
    @comparisons[:is_equal_to] = value
    self
  end

  def is_less_than(value)
    @comparisons[:is_less_than] = value
    self
  end

  def is_less_than_or_equal_to(value)
    @comparisons[:is_less_than_or_equal_to] = value
    self
  end

  def is_other_than(value)
    @comparisons[:is_other_than] = value
    self
  end

  private

  attr_accessor(
    :attribute,
    :expected_message,
    :validate_is_not_in_future,
    :comparisons,
    :descriptions,
    :failure_message_description
  )

  def allow_valid_dates
    valid_dates = [Time.zone.today, Time.zone.today.last_month]
    valid_dates.none? do |valid_date|
      @subject.send("#{@attribute}=", valid_date)
      @subject.valid?
      @subject.errors[@attribute].include?(@expected_message)
    end
  end

  def allow_valid_string_dates
    valid_string_dates = ['19/04/2016', '19/03/2016']
    valid_string_dates.none? do |valid_string_date|
      @subject.send("#{@attribute}=", valid_string_date)
      @subject.valid?
      @subject.errors[@attribute].include?(@expected_message)
    end
  end

  def disallow_invalid_dates
    invalid_dates = ['30/02/2016', '19/19/2016']
    invalid_dates.all? do |invalid_date|
      @subject.send("#{@attribute}=", invalid_date)
      @subject.valid?
      @subject.errors[@attribute].include?(@expected_message)
    end
  end

  def do_validate_is_not_in_future
    return true if !@validate_is_not_in_future

    @failure_message_description = "in the future"
    @descriptions << "not in future"
    @expected_message = I18n.t(
      'errors.messages.not_in_future'
    )

    allow_present_date && allow_past_date && disallow_future_date
  end

  def allow_present_date
    @subject.send("#{@attribute}=", Time.zone.today)
    @subject.valid?
    @subject.errors[@attribute].exclude?(@expected_message)
  end

  def allow_past_date
    @subject.send("#{@attribute}=", Time.zone.yesterday)
    @subject.valid?
    @subject.errors[@attribute].exclude?(@expected_message)
  end

  def disallow_future_date
    @subject.send("#{@attribute}=", Time.zone.tomorrow)
    @subject.valid?
    @subject.errors[@attribute].include?(@expected_message)
  end

  def do_comparisons
    return true if @comparisons.empty?

    @comparisons.all? do |comparison, value|
      self.send("do_#{comparison}_comparison", value)
    end
  end

  def do_is_greater_than_comparison(value)
    @failure_message_description = "not greater than #{value}"
    @descriptions << "greater than #{value}"
    @expected_message = I18n.t(
      'errors.messages.greater_than',
      count: @subject.class.human_attribute_name(value)
    )

    allow_greater_than(value) && disallow_equal_to(value) && disallow_less_than(value)
  end

  def do_is_greater_than_or_equal_to_comparison(value)
    @failure_message_description = "not greater than or equal to #{value}"
    @descriptions << "greater than or equal to #{value}"
    @expected_message = I18n.t(
      'errors.messages.greater_than_or_equal_to',
      count: @subject.class.human_attribute_name(value)
    )

    allow_greater_than(value) && allow_equal_to(value) && disallow_less_than(value)
  end

  def do_is_equal_to_comparison(value)
    @failure_message_description = "not equal to #{value}"
    @descriptions << "equal to #{value}"
    @expected_message = I18n.t(
      'errors.messages.equal_to',
      count: @subject.class.human_attribute_name(value)
    )

    allow_equal_to(value) && disallow_greater_than(value) && disallow_less_than(value)
  end

  def do_is_less_than_comparison(value)
    @failure_message_description = "not less than #{value}"
    @descriptions << "less than #{value}"
    @expected_message = I18n.t(
      'errors.messages.less_than',
      count: @subject.class.human_attribute_name(value)
    )

    allow_less_than(value) && disallow_greater_than(value) && disallow_equal_to(value)
  end

  def do_is_less_than_or_equal_to_comparison(value)
    @failure_message_description = "not less than or equal to #{value}"
    @descriptions << "less than or equal to #{value}"
    @expected_message = I18n.t(
      'errors.messages.less_than_or_equal_to',
      count: @subject.class.human_attribute_name(value)
    )

    allow_less_than(value) && allow_equal_to(value) && disallow_greater_than(value)
  end

  def do_is_other_than_comparison(value)
    @failure_message_description = "not other than #{value}"
    @descriptions << "other than #{value}"
    @expected_message = I18n.t(
      'errors.messages.other_than',
      count: @subject.class.human_attribute_name(value)
    )

    disallow_equal_to(value)
  end

  def allow_greater_than(value)
    @subject.send("#{@attribute}=", '02/01/2016')
    @subject.send("#{value}=", '01/01/2016')
    @subject.valid?
    @subject.errors[@attribute].exclude?(@expected_message)
  end

  def allow_equal_to(value)
    @subject.send("#{@attribute}=", '01/01/2016')
    @subject.send("#{value}=", '01/01/2016')
    @subject.valid?
    @subject.errors[@attribute].exclude?(@expected_message)
  end

  def allow_less_than(value)
    @subject.send("#{@attribute}=", '01/01/2016')
    @subject.send("#{value}=", '02/01/2016')
    @subject.valid?
    @subject.errors[@attribute].exclude?(@expected_message)
  end

  def disallow_greater_than(value)
    @subject.send("#{@attribute}=", '02/01/2016')
    @subject.send("#{value}=", '01/01/2016')
    @subject.valid?
    @subject.errors[@attribute].include?(@expected_message)
  end

  def disallow_equal_to(value)
    @subject.send("#{@attribute}=", '01/01/2016')
    @subject.send("#{value}=", '01/01/2016')
    @subject.valid?
    @subject.errors[@attribute].include?(@expected_message)
  end

  def disallow_less_than(value)
    @subject.send("#{@attribute}=", '01/01/2016')
    @subject.send("#{value}=", '02/01/2016')
    @subject.valid?
    @subject.errors[@attribute].include?(@expected_message)
  end
end
