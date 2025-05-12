class SetActiveToAllDailyFrequencyStudents < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      UPDATE daily_frequency_students set active = 't';
    SQL
  end
end
