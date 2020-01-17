class AdjustPeriodOnDailyFrequencies < ActiveRecord::Migration
  def change
    DailyFrequency.includes(:classroom).where(period: 0).each do |daily_frequency|
      period = daily_frequency.classroom.period

      daily_frequency.update(period: period)
    end
  end
end
