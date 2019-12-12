class AddShowDailyActivitiesInknowledgeAreaContentRecordReportToGeneralConfigurations < ActiveRecord::Migration
  def change
    add_column :general_configurations,
               :show_daily_activities_in_knowledge_area_content_record_report,
               :boolean,
               default: false
  end
end
