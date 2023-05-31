class RemoveTestTypeFromTestSettingTests < ActiveRecord::Migration[4.2]
  def change
    remove_column :test_setting_tests, :test_type
  end
end
