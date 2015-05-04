# encoding: utf-8
class SchoolCalendarEventsSeeder
  attr_accessor :school_calendar

  def initialize(options)
    self.school_calendar = options[:school_calendar]
  end

  def seed
    year = school_calendar.year.to_s

    SchoolCalendarEvent.create!(school_calendar: school_calendar, description: "Feriado - Ano novo " + year, event_date: year + '-01-01', event_type: EventTypes::NO_SCHOOL)
    SchoolCalendarEvent.create!(school_calendar: school_calendar, description: "Feriado - Tiradentes", event_date: year + '-04-21', event_type: EventTypes::NO_SCHOOL)
    SchoolCalendarEvent.create!(school_calendar: school_calendar, description: "Feriado - Dia do trabalho", event_date: year + '-05-01', event_type: EventTypes::NO_SCHOOL)
    SchoolCalendarEvent.create!(school_calendar: school_calendar, description: "Feriado - Dia da independência", event_date: year + '-09-07', event_type: EventTypes::NO_SCHOOL)
    SchoolCalendarEvent.create!(school_calendar: school_calendar, description: "Feriado - Nossa Senhora Aparecida", event_date: year + '-10-12', event_type: EventTypes::NO_SCHOOL)
    SchoolCalendarEvent.create!(school_calendar: school_calendar, description: "Feriado - Finados", event_date: year + '-11-02', event_type: EventTypes::NO_SCHOOL)
    SchoolCalendarEvent.create!(school_calendar: school_calendar, description: "Feriado - Proclamação da República", event_date: year + '-11-15', event_type: EventTypes::NO_SCHOOL)
    SchoolCalendarEvent.create!(school_calendar: school_calendar, description: "Feriado - Natal", event_date: year + '-12-25', event_type: EventTypes::NO_SCHOOL)
  end
end