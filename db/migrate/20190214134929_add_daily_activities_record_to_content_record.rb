class AddDailyActivitiesRecordToContentRecord < ActiveRecord::Migration[4.2]
  def change
    add_column :content_records, :daily_activities_record, :text
  end
end
