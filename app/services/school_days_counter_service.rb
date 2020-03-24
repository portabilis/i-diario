class SchoolDaysCounterService
  def initialize(params)
    @unities = [params.fetch(:unities)].flatten
    @start_date = params.fetch(:start_date, nil)
    @end_date = params.fetch(:end_date, nil)
    @year = params.fetch(:year, nil)

    raise ArgumentError if @year.blank?
  end

  def all_school_days
    Rails.cache.fetch('school_days_by_unity', expires_in: 1.year) do
      fetch_school_days(@unities, nil, nil)
    end
  end

  def fetch_school_days(unities, start_date, end_date)
    school_days_by_unity = {}

    unities.each do |unity|
      school_days = school_days_fetcher(unity, start_date, end_date)

      next if school_days.blank?

      school_days_by_unity[unity.id] = school_days
    end

    school_days_by_unity
  end

  def school_days_fetcher(unity, start_date, end_date)
    school_calendar = SchoolCalendar.by_year(@year).by_unity_id(unity.id).first

    return if school_calendar.blank?

    start_date ||= school_calendar.steps.min_by(&:step_number).start_at
    end_date ||= school_calendar.steps.max_by(&:step_number).end_at

    SchoolDayChecker.new(
      school_calendar,
      start_date,
      nil,
      nil,
      nil
    ).school_dates_between(
      start_date,
      end_date
    ).size
  end
end
