class SchoolTermDayValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    school_term = options[:school_term].call(record)

    return unless value && school_term

    unless school_term.school_calendar_step_day?(value)
      record.errors.add(attribute, I18n.t('errors.messages.not_school_term_day'))
    end
  end
end
