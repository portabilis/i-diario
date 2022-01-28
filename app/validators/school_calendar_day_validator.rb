class SchoolCalendarDayValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return unless value && record.school_calendar

    unless record.school_calendar.school_day?(value, record.try(:classroom).try(:grade).try(:id), record.try(:classroom).try(:id), record.try(:discipline).try(:id))
      step = record.school_calendar.steps.posting_date_after_and_before(value).first
      message = step ? I18n.t('errors.messages.not_school_calendar_day') : I18n.t('errors.messages.is_not_between_steps')

      record.errors.add(attribute, message)
    end
  end
end
