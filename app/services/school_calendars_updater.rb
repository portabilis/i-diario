class SchoolCalendarsUpdater
  def self.update!(school_calendars)
    new(school_calendars).update!
  end

  def initialize(school_calendars)
    self.school_calendars = school_calendars
  end

  def update!
    selected_school_calendars_to_update.each do |school_calendar_params|
      school_calendar = SchoolCalendar.find_by(id: school_calendar_params['school_calendar_id'])

      school_calendar_params['steps'].each_with_index do |step_params, index|
        if school_calendar.steps[index].present?
          school_calendar.steps[index].start_at = step_params['start_at']
          school_calendar.steps[index].start_date_for_posting = step_params['start_date_for_posting']
          school_calendar.steps[index].end_at = step_params['end_at']
          school_calendar.steps[index].end_date_for_posting = step_params['end_date_for_posting']
        else
          school_calendar.steps.build(
            start_at: step_params['start_at'],
            end_at: step_params['end_at'],
            start_date_for_posting: step_params['start_date_for_posting'],
            end_date_for_posting: step_params['end_date_for_posting']
          )
        end
      end

      school_calendar.save!
    end
  end

  private

  attr_accessor :school_calendars

  def selected_school_calendars_to_update
    school_calendars.select { |school_calendar| school_calendar['unity_id'].present? && school_calendar['school_calendar_id'].present? }
  end
end
