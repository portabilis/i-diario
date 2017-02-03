class RemoveFixTestsFromTestSettings < ActiveRecord::Migration
  def change
    remove_column :test_settings, :fix_tests, :boolean
  end
end
