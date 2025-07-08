class AddPeriodToIeducarApiSynchronizations < ActiveRecord::Migration[5.0]
  def change
    add_column :ieducar_api_synchronizations, :period, :string
  end
end