class ApplyAdjustPeriodOnDailyFrequencies < ActiveRecord::Migration
  def change
    DailyFrequency.includes(:classroom).where(period: 0).each do |daily_frequency|
      classroom_id = daily_frequency.classroom_id
      period = Classroom.with_discarded.find(classroom_id).period

      daily_frequency.update(period: period)
    end
  end
end
