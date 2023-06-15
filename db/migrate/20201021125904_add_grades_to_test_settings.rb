class AddGradesToTestSettings < ActiveRecord::Migration[4.2]
  def change
    add_column :test_settings, :grades, :integer, array: true, default: []
  end
end
