class AdjustPeriodOnDailyFrequencies < ActiveRecord::Migration[4.2]
  def change
    DailyFrequency.includes(:classroom).where(period: 0).each do |daily_frequency|
      classroom_id = daily_frequency.classroom_id
      frequency_date = daily_frequency.frequency_date
      period = Classroom.with_discarded.find(classroom_id).period

      if DailyFrequency.find_by(classroom_id: classroom_id, frequency_date: frequency_date, period: period)
        DailyFrequencyStudent.where(daily_frequency_id: daily_frequency.id).delete_all
        daily_frequency.delete
      else
        daily_frequency.update_column(:period, period)
      end
    end
  end
end
