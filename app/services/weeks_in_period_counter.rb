class WeeksInPeriodCounter
  def self.count(start_date, end_date)
    new(start_date, end_date).count
  end

  def initialize(start_date, end_date)
    @start_date = start_date
    @end_date = end_date
  end

  def count
    week_counted = false
    weeks = 0

    (@start_date..@end_date).each do |date|
      week_counted = false if date.monday?
      next if week_counted || is_weekend?(date)
      weeks += 1
      week_counted = true
    end
    weeks
  end

  def is_weekend?(date)
    date.saturday? || date.sunday?
  end
end
