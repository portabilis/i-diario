class CreateIepSelectedOptions < ActiveRecord::Migration[5.0]
  def change
    create_table :iep_selected_options do |t|
      t.integer :individualized_educational_plan_id, null: false
      t.integer :iep_option_id, null: false

      t.timestamps
    end

    add_index :iep_selected_options, [:individualized_educational_plan_id, :iep_option_id],
              unique: true, name: :idx_iep_selected_options_on_iep_and_option
    add_index :iep_selected_options, :iep_option_id,
              name: :idx_iep_selected_options_on_option

    add_foreign_key :iep_selected_options, :individualized_educational_plans,
                    column: :individualized_educational_plan_id
    add_foreign_key :iep_selected_options, :iep_options, column: :iep_option_id
  end
end
