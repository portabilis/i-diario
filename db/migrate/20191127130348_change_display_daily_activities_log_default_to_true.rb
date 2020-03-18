class ChangeDisplayDailyActivitiesLogDefaultToTrue < ActiveRecord::Migration
  def change
    change_column_default :general_configurations, :display_daily_activies_log, true
  end
end
