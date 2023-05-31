class PopulateSchoolTermTypes < ActiveRecord::Migration[4.2]
  def change
    (
      SchoolCalendar.uniq.pluck(:step_type_description) +
      SchoolCalendarClassroom.uniq.pluck(:step_type_description)
    ).uniq.each do |step_type_description|
      step = SchoolCalendarStep.joins(:school_calendar)
                               .where(
                                 school_calendars: {
                                   step_type_description: step_type_description
                                 }
                               ).group(:school_calendar_id)
                               .count(:school_calendar_id)
                               &.first

      step ||= SchoolCalendarClassroomStep.joins(:school_calendar_classroom)
                                          .where(
                                            school_calendar_classrooms: {
                                              step_type_description: step_type_description
                                            }
                                          ).group(:school_calendar_classroom_id)
                                          .count(:school_calendar_classroom_id)
                                          &.first
      next if step.blank?

      steps_number = step.second
      description = "#{step_type_description} (#{steps_number} #{'etapa'.pluralize(steps_number)})"

      SchoolTermType.create!(description: description, steps_number: steps_number)
    end
  end
end
