class UpdatePeriodOnDailyFrequencies < ActiveRecord::Migration
  def change
    DailyFrequency.includes(:classroom).joins(:classroom).each do |daily_frequency|
      classroom = daily_frequency.classroom
      classroom_period = classroom.period
      frequecy_period = daily_frequency.period

      next if classroom_period.blank?
      next if classroom_period == Periods::FULL
      next if frequecy_period == classroom_period
      next if DailyFrequency.find_by(
        classroom_id: classroom.id,
        frequency_date: daily_frequency.frequency_date,
        period: classroom_period
      )

      daily_frequency.update(period: daily_frequency.classroom.period)
    end
  end
end
