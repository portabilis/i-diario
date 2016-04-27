class SchoolCalendarDayValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return unless value && record.school_calendar

    unless record.school_calendar.school_day?(value, record.try(:grade).try(:classroom).try(:id), record.try(:classroom).try(:id))
      record.errors.add(attribute, I18n.t('errors.messages.not_school_calendar_day'))
    end
  end
end
