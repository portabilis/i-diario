class SchoolCalendarsParser
  def initialize(configuration)
    self.configuration = configuration
  end

  def parse!
    school_calendars_from_api = api.fetch['escolas']
    build_school_calendars_to_synchronize(school_calendars_from_api)
  end

  def self.parse!(configuration)
    new(configuration).parse!
  end

  private

  attr_accessor :configuration

  def api
    IeducarApi::SchoolCalendars.new(configuration.to_api)
  end

  def build_school_calendars_to_synchronize(school_calendars_from_api)
    build_new_school_calendars(school_calendars_from_api) + build_existing_school_calendars(school_calendars_from_api)
  end

  def build_new_school_calendars(school_calendars_from_api)
    new_school_calendars_from_api = fetch_new_school_calendars_from_api(school_calendars_from_api)

    new_school_calendars_from_api.map do |school_calendar_from_api|
      unity = Unity.find_by(api_code: school_calendar_from_api['escola_id'])
      school_calendar = SchoolCalendar.new(
        unity: unity,
        year: school_calendar_from_api['ano'].to_i,
        number_of_classes: 4
      )

      school_calendar_from_api['etapas'].each do |step|
        school_calendar.steps.build(
          start_at: step['data_inicio'],
          end_at: step['data_fim'],
          start_date_for_posting: step['data_inicio'],
          end_date_for_posting: step['data_fim']
        )
      end

      school_calendar
    end
  end

  def fetch_new_school_calendars_from_api(school_calendars_from_api)
    school_calendars_from_api.select do |school_calendar_from_api|
      unity_api_code = school_calendar_from_api['escola_id']
      year = school_calendar_from_api['ano'].to_i

      Unity.exists?(api_code: unity_api_code) &&
        SchoolCalendar.by_year(year).by_unity_api_code(unity_api_code).none?
    end
  end

  def build_existing_school_calendars(school_calendars_from_api)
    school_calendars_to_synchronize = []
    existing_school_calendars_from_api = fetch_existing_school_calendars_from_api(school_calendars_from_api)

    existing_school_calendars_from_api.each do |school_calendar_from_api|
      unity_api_code = school_calendar_from_api['escola_id']
      year = school_calendar_from_api['ano'].to_i

      unity = Unity.find_by(api_code: unity_api_code)
      school_calendar = SchoolCalendar.by_year(year).by_unity_api_code(unity_api_code).first

      school_calendar_from_api['etapas'].each_with_index do |step, index|
        if school_calendar.steps[index].present?
          update_step_start_at(school_calendar, index, step)
          update_step_end_at(school_calendar, index, step)
        else
          school_calendar.steps.build(
            start_at: step['data_inicio'],
            end_at: step['data_fim'],
            start_date_for_posting: step['data_inicio'],
            end_date_for_posting: step['data_fim']
          )
        end
      end

      need_to_synchronize = school_calendar.changed? || school_calendar.steps.any?(&:new_record?) || school_calendar.steps.any?(&:changed?)
      school_calendars_to_synchronize << school_calendar if need_to_synchronize
    end

    school_calendars_to_synchronize
  end

  def fetch_existing_school_calendars_from_api(school_calendars_from_api)
    school_calendars_from_api.select do |school_calendar_from_api|
      unity_api_code = school_calendar_from_api['escola_id']
      year = school_calendar_from_api['ano'].to_i

      Unity.exists?(api_code: unity_api_code) &&
        SchoolCalendar.by_year(year).by_unity_api_code(unity_api_code).any?
    end
  end

  def update_step_start_at(school_calendar, index, step)
    if school_calendar.steps[index].start_at != Date.parse(step['data_inicio'])
      school_calendar.steps[index].start_at = step['data_inicio']
      school_calendar.steps[index].start_date_for_posting = step['data_inicio']
    end
  end

  def update_step_end_at(school_calendar, index, step)
    if school_calendar.steps[index].end_at != Date.parse(step['data_fim'])
      school_calendar.steps[index].end_at = step['data_fim']
      school_calendar.steps[index].end_date_for_posting = step['data_fim']
    end
  end
end
