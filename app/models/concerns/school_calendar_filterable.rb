module SchoolCalendarFilterable
  extend ActiveSupport::Concern

  included do
    def self.current_year_school_term_types(year, unity_id, add_yearly)
      @school_term_types ||= Hash.new do |h, params|
        year_param = params[0]
        unity_id_param = params[1]
        add_yearly_param = params[2]

        school_calendar = SchoolCalendar.includes(:steps).where(year: year_param)
        school_calendar = school_calendar.where(unity_id: unity_id_param) if unity_id_param
        school_calendar = school_calendar.map { |calendar| step_type_description_formatter(calendar) }.uniq

        school_calendar_classroom = SchoolCalendarClassroom.joins(:school_calendar)
                                                           .includes(:classroom_steps)
                                                           .where(
                                                             school_calendars: {
                                                               year: year_param
                                                             }
                                                           )
        if unity_id_param
          school_calendar_classroom = school_calendar_classroom.where(school_calendars: {
                                                                        unity_id: unity_id_param
                                                                      })
        end

        school_calendar_classroom = school_calendar_classroom.map { |calendar|
          step_type_description_formatter(calendar)
        }.uniq

        school_term_types = SchoolTermType.where(description: school_calendar + school_calendar_classroom)
        school_term_types << SchoolTermType.first if add_yearly_param

        h[params] = school_term_types
      end

      @school_term_types[[year, unity_id, add_yearly]]
    end

    def self.step_type_description_formatter(calendar)
      steps_number = calendar.is_a?(SchoolCalendar) ? calendar.steps.count : calendar.classroom_steps.count

      "#{calendar.step_type_description} (#{steps_number} #{'etapa'.pluralize(steps_number)})"
    end
  end
end
