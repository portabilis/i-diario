class DateValidator < ActiveModel::EachValidator
  CHECKS = {
    greater_than: :>,
    greater_than_or_equal_to: :>=,
    equal_to: :==,
    less_than: :<,
    less_than_or_equal_to: :<=,
    other_than: :!=
  }.freeze

  def validate_each(record, attribute, value)
    return unless value.present?

    unless is_date?(value)
      record.errors.add(attribute, I18n.t('errors.messages.invalid_date'))
      return
    end

    value = parse_as_date(value)

    if options[:not_in_future].present? && value > Time.zone.today
      record.errors.add(attribute, I18n.t('errors.messages.not_in_future'))
      return
    end

    options.slice(*CHECKS.keys).each do |option, raw_option_value|
      case raw_option_value
      when Proc
        option_value = raw_option_value.call(record)
        next if option_value.blank? || !is_date?(option_value)
        option_value = parse_as_date(option_value)
        message_value = parse_as_localized_date(option_value)
      when Symbol
        option_value = record.send(raw_option_value)
        next if option_value.blank? || !is_date?(option_value)
        option_value = parse_as_date(option_value)
        message_value = record.class.human_attribute_name(raw_option_value)
      end

      unless value.send(CHECKS[option], option_value)
        record.errors.add(attribute, option, count: message_value)
      end
    end
  end

  private

  def is_date?(value)
    parse_as_date(value).present?
  rescue ArgumentError, TypeError
    false
  end

  def parse_as_date(value)
    Date.parse(value.to_s)
  end

  def parse_as_localized_date(value)
    I18n::Alchemy::DateParser.localize(value)
  end
end
