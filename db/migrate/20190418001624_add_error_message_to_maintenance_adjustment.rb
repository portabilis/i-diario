class AddErrorMessageToMaintenanceAdjustment < ActiveRecord::Migration
  def change
    add_column :maintenance_adjustments, :error_message, :text
  end
end
