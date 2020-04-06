class SchoolDaysCounterService
  def initialize(params)
    @unities = [params.fetch(:unities)].flatten
    @all_unities_size = params.fetch(:all_unities_size, nil)
    @start_date = params.fetch(:start_date, nil)
    @end_date = params.fetch(:end_date, nil)
    @year = params.fetch(:year, nil)

    raise ArgumentError if @year.blank? || @all_unities_size.blank?
  end

  def school_days
    return all_school_days if @unities.size == @all_unities_size && @start_date.blank? && @end_date.blank?

    fetch_school_days(@unities, @start_date, @end_date)
  end

  private

  def all_school_days
    fetch_school_days(@unities, nil, nil)
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

    start_date = start_date.presence || school_calendar.steps.min_by(&:step_number).start_at
    end_date = end_date.presence || school_calendar.steps.max_by(&:step_number).end_at

    school_days = UnitySchoolDay.by_unity_id(unity.id).by_date_between(start_date, end_date).size

    { school_days: school_days, start_date: start_date, end_date: end_date }
  end
end
