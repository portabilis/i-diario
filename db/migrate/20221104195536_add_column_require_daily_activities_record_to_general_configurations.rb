class AddColumnRequireDailyActivitiesRecordToGeneralConfigurations < ActiveRecord::Migration[4.2]
  def change
    add_column :general_configurations, :require_daily_activities_record, :string, default: "does_not_require"
  end
end
