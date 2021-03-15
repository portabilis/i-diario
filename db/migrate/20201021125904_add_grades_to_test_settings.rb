class AddGradesToTestSettings < ActiveRecord::Migration
  def change
    add_column :test_settings, :grades, :integer, array: true, default: []
  end
end
