class CreateMaintenanceAdjustmentsUnities < ActiveRecord::Migration[4.2]
  def change
    create_table :maintenance_adjustments_unities, id: false do |t|
      t.belongs_to :maintenance_adjustment
      t.belongs_to :unity
    end

    add_index :maintenance_adjustments_unities, :maintenance_adjustment_id,
      :name => 'idx_maintenance_adjustments_unities_on_maintenance_adjust_id'
    add_index :maintenance_adjustments_unities, :unity_id,
      :name => 'idx_maintenance_adjustments_unities_on_unity_id'
  end
end
