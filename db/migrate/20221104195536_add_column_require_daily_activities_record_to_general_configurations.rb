class AddColumnRequireDailyActivitiesRecordToGeneralConfigurations < ActiveRecord::Migration
  def change
    add_column :general_configurations, :require_daily_activities_record, :string, default: "does_not_require"
  end
end
