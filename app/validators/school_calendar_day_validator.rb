class SchoolCalendarDayValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return unless value && record.school_calendar

    classroom_id = record.try(:classroom).try(:id)
    grade_ids = record.try(:grade_ids) || record.try(:classroom).try(:grades)&.pluck(:id)
    discipline_id = record.try(:discipline).try(:id)
    school_day = true
    message = ''

    grade_ids&.each do |grade_id|
      school_day = false unless record.school_calendar.day_allows_entry?(
        value, grade_id, classroom_id, discipline_id
      )
      step = record.school_calendar.steps.posting_date_after_and_before(value).first
      message = step ? I18n.t('errors.messages.not_school_calendar_day') : I18n.t('errors.messages.is_not_between_steps')

      break unless school_day
    end

    record.errors.add(attribute, message) unless school_day
  end
end
