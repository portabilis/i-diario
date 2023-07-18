class ChangeDisplayDailyActivitiesLogToTrue < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      UPDATE general_configurations
        SET display_daily_activies_log = true;
    SQL
  end
end
