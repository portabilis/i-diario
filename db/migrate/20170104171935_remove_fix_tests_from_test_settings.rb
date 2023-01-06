class RemoveFixTestsFromTestSettings < ActiveRecord::Migration[4.2]
  def change
    remove_column :test_settings, :fix_tests, :boolean
  end
end
