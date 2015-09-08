class SchoolCalendarsParser
  def initialize(configuration)
    self.configuration = configuration
  end

  def parse!
    build_records(api.fetch(ano: Date.today.year)['escolas'])
  end

  def self.parse!(configuration)
    new(configuration).parse!
  end

  private

  attr_accessor :configuration

  def api
    IeducarApi::SchoolCalendars.new(configuration.to_api)
  end

  def build_records(collection)
    new_school_calendars = []

    collection.each do |record|
      if Unity.exists?(api_code: record['escola_id']) && !SchoolCalendar.joins(:unity).exists?(unities: { api_code: record['escola_id'] })
        unity = Unity.find_by_api_code(record['escola_id'])
        new_school_calendar = SchoolCalendar.new(unity: unity,
                                                 year: Date.today.year,
                                                 number_of_classes: 4)
        record['etapas'].each do |step|
          new_school_calendar.steps.build(start_at: step['data_inicio'],
                                          end_at:   step['data_fim'],
                                          start_date_for_posting: step['data_inicio'],
                                          end_date_for_posting: step['data_fim'])
        end

        new_school_calendars << new_school_calendar
      end
    end

    new_school_calendars
  end
end
