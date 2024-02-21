class AddAllowClassNumberOnContentRecordsToGeneralConfigurations < ActiveRecord::Migration
  def up
    add_column :general_configurations, :allow_class_number_on_content_records, :boolean, default: false
  end

  def down
    remove_column :general_configurations, :allow_class_number_on_content_records
  end
end
