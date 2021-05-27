class SchoolCalendarDayValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return unless value && record.school_calendar

    classroom_id = record.try(:classroom).try(:id)
    grade_ids = record.try(:grade_ids) || record.try(:classroom).try(:grades)&.pluck(:id)
    discipline_id = record.try(:discipline).try(:id)
    school_day = true

    loop do
      grade_id = grade_ids&.shift
      school_day = false unless record.school_calendar.school_day?(value, grade_id, classroom_id, discipline_id)

      break if grade_ids.blank? || !school_day
    end

    record.errors.add(attribute, I18n.t('errors.messages.not_school_calendar_day')) unless school_day
  end
end
