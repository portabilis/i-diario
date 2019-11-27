class ChangeDisplayDailyActivitiesLogToTrue < ActiveRecord::Migration
  def change
    execute <<-SQL
      UPDATE general_configurations
        SET display_daily_activies_log = true;
    SQL
  end
end
