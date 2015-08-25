class AddAllowBreakUpToTestSettingTests < ActiveRecord::Migration
  def change
    add_column :test_setting_tests, :allow_break_up, :boolean, default: false
  end
end
