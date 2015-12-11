class SchoolCalendarsParser
  def initialize(configuration)
    self.configuration = configuration
  end

  def parse!
    school_calendars_from_api = api.fetch(ano: Time.zone.today.year)['escolas']
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
    school_calendars_to_synchronize = []

    new_school_calendars_from_api = school_calendars_from_api.select do |school_calendar_from_api|
      unity_api_code = school_calendar_from_api['escola_id']
      Unity.exists?(api_code: unity_api_code) &&
      !SchoolCalendar.joins(:unity).exists?(unities: { api_code: unity_api_code })
    end

    new_school_calendars_from_api.each do |new_school_calendar_from_api|
      unity_api_code = new_school_calendar_from_api['escola_id']
      unity = Unity.find_by(api_code: unity_api_code)

      new_school_calendar = SchoolCalendar.new(unity: unity,
                                               year: Time.zone.today.year,
                                               number_of_classes: 4)

      new_school_calendar_from_api['etapas'].each do |step|
        new_school_calendar.steps.build(start_at: step['data_inicio'],
                                        end_at:   step['data_fim'],
                                        start_date_for_posting: step['data_inicio'],
                                        end_date_for_posting:   step['data_fim'])
      end

      school_calendars_to_synchronize << new_school_calendar
    end

    school_calendars_to_synchronize
  end

  def build_existing_school_calendars(school_calendars_from_api)
    school_calendars_to_synchronize = []

    existing_school_calendars_from_api = school_calendars_from_api.select do |school_calendar_from_api|
      unity_api_code = school_calendar_from_api['escola_id']
      Unity.exists?(api_code: unity_api_code) &&
      SchoolCalendar.joins(:unity).exists?(unities: { api_code: unity_api_code })
    end

    existing_school_calendars_from_api.each do |existing_school_calendar_from_api|
      unity_api_code = existing_school_calendar_from_api['escola_id']
      unity = Unity.find_by(api_code: unity_api_code)
      school_calendar = SchoolCalendar.joins(:unity).find_by(unities: { api_code: unity_api_code })

      need_to_synchronize = false
      existing_school_calendar_from_api['etapas'].each_with_index do |step, index|
        if school_calendar.steps[index].start_at != Date.parse(step['data_inicio'])
          need_to_synchronize = true
          school_calendar.steps[index].start_at = step['data_inicio']
          school_calendar.steps[index].start_date_for_posting = step['data_inicio']
        end

        if school_calendar.steps[index].end_at != Date.parse(step['data_fim'])
          need_to_synchronize = true
          school_calendar.steps[index].end_at = step['data_fim']
          school_calendar.steps[index].end_date_for_posting = step['data_fim']
        end
      end

      school_calendars_to_synchronize << school_calendar if need_to_synchronize
    end

    school_calendars_to_synchronize
  end
end
