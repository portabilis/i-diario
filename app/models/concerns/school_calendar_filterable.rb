module SchoolCalendarFilterable
  extend ActiveSupport::Concern

  included do
    def self.current_year_school_term_types(year, unity_id, add_yearly)
      @school_term_types ||= Hash.new do |h, params|
        year_param = params[0]
        unity_id_param = params[1]
        add_yearly_param = params[2]

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

        school_term_types = SchoolTermType.where(description: school_calendar + school_calendar_classroom)
        school_term_types << SchoolTermType.first if add_yearly_param

        h[params] = school_term_types
      end

      @school_term_types[[year, unity_id, add_yearly]]
    end
  end
end
