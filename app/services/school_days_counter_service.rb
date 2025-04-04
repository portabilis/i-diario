class SchoolDaysCounterService
  def initialize(params)
    @unities = [params.fetch(:unities)].flatten
    @all_unities_size = params.fetch(:all_unities_size, nil)
    @start_date = params.fetch(:start_date, nil)
    @end_date = params.fetch(:end_date, nil)
    @year = params.fetch(:year, nil)

    raise ArgumentError if @year.blank? || @all_unities_size.blank?

    preload_school_calendars
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
    unity_ids = unities.map(&:id)
    counts_by_unity = UnitySchoolDay
                        .where(unity_id: unity_ids)
                        .by_date_between(start_date, end_date)
                        .group(:unity_id)
                        .count
  
    school_days_by_unity = {}
  
    unities.each do |unity|
      school_calendar = @school_calendars_by_unity[unity.id]
      next if school_calendar.blank?
  
      real_start_date = start_date.presence || school_calendar.steps.min_by(&:step_number).start_at
      real_end_date = end_date.presence || school_calendar.steps.max_by(&:step_number).end_at
  
      school_days_count = counts_by_unity[unity.id] || 0
  
      school_days_by_unity[unity.id] = {
        school_days: school_days_count,
        start_date: real_start_date,
        end_date: real_end_date
      }
    end
  
    school_days_by_unity
  end

  def preload_school_calendars
    school_calendars = SchoolCalendar
                         .by_year(@year)
                         .where(unity_id: @unities.map(&:id))
                         .includes(:steps) # para evitar N+1 nas steps
                         .to_a

    @school_calendars_by_unity = school_calendars.index_by(&:unity_id)
  end
end