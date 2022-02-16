# encoding: utf-8
class SchoolCalendarEventsSeeder
  attr_accessor :school_calendar

  def initialize(options)
    self.school_calendar = options[:school_calendar]
  end

  def seed
    year = school_calendar.year.to_s

    SchoolCalendarEvent.new(school_calendar: school_calendar, description: "Feriado - Tiradentes", start_date: year + '-04-21', end_date: year + '-04-21', event_type: EventTypes::NO_SCHOOL, legend: "E").save(validate: false)
    SchoolCalendarEvent.new(school_calendar: school_calendar, description: "Feriado - Dia do trabalho", start_date: year + '-05-01', end_date: year + '-05-01', event_type: EventTypes::NO_SCHOOL, legend: "E").save(validate: false)
    SchoolCalendarEvent.new(school_calendar: school_calendar, description: "Feriado - Dia da independência", start_date: year + '-09-07', end_date: year + '-09-07', event_type: EventTypes::NO_SCHOOL, legend: "E").save(validate: false)
    SchoolCalendarEvent.new(school_calendar: school_calendar, description: "Feriado - Ano novo " + year, start_date: year + '-01-01', end_date: year + '-01-01', event_type: EventTypes::NO_SCHOOL, legend: "E").save(validate: false)
    SchoolCalendarEvent.new(school_calendar: school_calendar, description: "Feriado - Nossa Senhora Aparecida", start_date: year + '-10-12', end_date: year + '-10-12', event_type: EventTypes::NO_SCHOOL, legend: "E").save(validate: false)
    SchoolCalendarEvent.new(school_calendar: school_calendar, description: "Feriado - Finados", start_date: year + '-11-02', end_date: year + '-11-02', event_type: EventTypes::NO_SCHOOL, legend: "E").save(validate: false)
    SchoolCalendarEvent.new(school_calendar: school_calendar, description: "Feriado - Proclamação da República", start_date: year + '-11-15', end_date: year + '-11-15', event_type: EventTypes::NO_SCHOOL, legend: "E").save(validate: false)
    SchoolCalendarEvent.new(school_calendar: school_calendar, description: "Feriado - Natal", start_date: year + '-12-25', end_date: year + '-12-25', event_type: EventTypes::NO_SCHOOL, legend: "E").save(validate: false)
  end
end
