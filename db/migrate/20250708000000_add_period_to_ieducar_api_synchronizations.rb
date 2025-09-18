class AddPeriodToIeducarApiSynchronizations < ActiveRecord::Migration[5.0]
  def up
    add_column :ieducar_api_synchronizations, :period, :string
  end

  def down
    remove_column :ieducar_api_synchronizations, :period
  end
end