class CreateUnityEquipments < ActiveRecord::Migration[4.2]
  def change
    create_table :unity_equipments do |t|
      t.integer :unity_id, index: true, null: false
      t.integer :code, null: false
      t.integer :biometric_type, null: false
    end
    add_foreign_key :unity_equipments, :unities
  end
end
