class SetActiveToAllDailyFrequencyStudents < ActiveRecord::Migration
  def change
    execute <<-SQL
      UPDATE daily_frequency_students set active = 't';
    SQL
  end
end
