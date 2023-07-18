class AddAllowBreakUpToTestSettingTests < ActiveRecord::Migration[4.2]
  def change
    add_column :test_setting_tests, :allow_break_up, :boolean, default: false
  end
end
