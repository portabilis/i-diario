class CreateIepMedications < ActiveRecord::Migration[5.0]
  def change
    create_table :iep_medications do |t|
      t.integer :individualized_educational_plan_id, null: false
      t.string :name
      t.string :dosage
      t.string :schedule

      t.timestamps
    end

    add_index :iep_medications, :individualized_educational_plan_id,
              name: :idx_iep_medications_on_iep

    add_foreign_key :iep_medications, :individualized_educational_plans,
                    column: :individualized_educational_plan_id
  end
end
