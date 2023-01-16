module SchoolCalendarFilterable
  extend ActiveSupport::Concern

  included do
    def self.current_year_school_term_types(year, unity_id, add_yearly)
      school_calendar = SchoolCalendar.includes(:steps).where(year: year)
      school_calendar = school_calendar.where(unity_id: unity_id) if unity_id
      school_calendar = school_calendar.map { |calendar| step_type_description_formatter(calendar) }.uniq

      school_calendar_classroom = SchoolCalendarClassroom.joins(:school_calendar)
                                                         .includes(:classroom_steps)
                                                         .where(
                                                           school_calendars: {
                                                             year: year
                                                           }
                                                         )
      if unity_id
        school_calendar_classroom = school_calendar_classroom.where(school_calendars: {
                                                                      unity_id: unity_id
                                                                    })
      end

      school_calendar_classroom = school_calendar_classroom.map { |calendar|
        step_type_description_formatter(calendar)
      }.uniq

      school_term_types = SchoolTermType.where(description: school_calendar + school_calendar_classroom).to_a
      school_term_types << SchoolTermType.find_by(description: 'Anual') if add_yearly

      school_term_types
    end

    def self.step_type_description_formatter(calendar)
      steps_number = calendar.is_a?(SchoolCalendar) ? calendar.steps.count : calendar.classroom_steps.count

      "#{calendar.step_type_description} (#{steps_number} #{'etapa'.pluralize(steps_number)})"
    end
  end
end
