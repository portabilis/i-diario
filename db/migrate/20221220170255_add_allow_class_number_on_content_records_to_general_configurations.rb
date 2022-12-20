class AddAllowClassNumberOnContentRecordsToGeneralConfigurations < ActiveRecord::Migration
  def change
    add_column :general_configurations, :allow_class_number_on_content_records, :boolean, default: false
  end
end
