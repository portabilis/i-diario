module SchoolCalendarFilterable
  extend ActiveSupport::Concern

  included do
    def self.current_year_school_term_types(year, unity_id)
      @school_term_types ||= Hash.new do |h, params|
        year_param = params[0]
        unity_id_param = params[1]

        school_calendar = SchoolCalendar.where(year: year_param)
        school_calendar = school_calendar.where(unity_id: unity_id_param) if unity_id_param
        school_calendar = school_calendar.pluck(:step_type_description)

        school_calendar_classroom = SchoolCalendarClassroom.joins(:school_calendar)
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

        school_calendar_classroom = school_calendar_classroom.pluck(:step_type_description)

        h[params] = SchoolTermType.where(description: school_calendar + school_calendar_classroom)
      end

      @school_term_types[[year, unity_id]]
    end
  end
end
