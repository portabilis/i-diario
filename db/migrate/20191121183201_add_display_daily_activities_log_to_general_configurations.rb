class AddDisplayDailyActivitiesLogToGeneralConfigurations < ActiveRecord::Migration
  def change
    add_column :general_configurations, :display_daily_activies_log, :boolean, default: false
  end
end
