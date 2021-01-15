class AddUnitiesToTestSettings < ActiveRecord::Migration
  def change
    add_column :test_settings, :unities, :integer, array: true, default: []
  end
end
