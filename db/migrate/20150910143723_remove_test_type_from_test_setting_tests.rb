class RemoveTestTypeFromTestSettingTests < ActiveRecord::Migration
  def change
    remove_column :test_setting_tests, :test_type
  end
end
