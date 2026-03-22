class AddErrorMessageToMaintenanceAdjustments < ActiveRecord::Migration[4.2]
  def change
    add_column :maintenance_adjustments, :error_message, :text
  end
end
