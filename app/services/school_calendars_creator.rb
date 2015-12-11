class SchoolCalendarsCreator
  def self.create!(school_calendars)
    new(school_calendars).create!
  end

  def initialize(school_calendars)
    self.school_calendars = school_calendars
  end

  def create!
    selected_school_calendars_to_create.each do |school_calendar_params|
      school_calendar = SchoolCalendar.new(year: Time.zone.today.year,
                                           unity_id: school_calendar_params['unity_id'],
                                           number_of_classes: school_calendar_params['number_of_classes'])

      school_calendar_params['steps'].each do |step_params|
        school_calendar.steps.build(start_at: step_params['start_at'],
                                    end_at: step_params['end_at'],
                                    start_date_for_posting: step_params['start_date_for_posting'],
                                    end_date_for_posting: step_params['end_date_for_posting'])
      end

      school_calendar.save!
    end
  end

  private

  attr_accessor :school_calendars

  def selected_school_calendars_to_create
    school_calendars.select { |school_calendar| school_calendar['unity_id'].present? && school_calendar['school_calendar_id'].blank? }
  end
end
