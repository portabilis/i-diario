class AddDailyActivitiesRecordToContentRecord < ActiveRecord::Migration
  def change
    add_column :content_records, :daily_activities_record, :text
  end
end
