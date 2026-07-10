class CreateIepCurricularPlanningOptions < ActiveRecord::Migration[5.0]
  def change
    create_table :iep_curricular_planning_options do |t|
      t.integer :iep_curricular_planning_id, null: false
      t.integer :iep_option_id, null: false

      t.timestamps
    end

    add_index :iep_curricular_planning_options, :iep_curricular_planning_id,
              name: :idx_iep_cpo_on_planning_id
    add_index :iep_curricular_planning_options, :iep_option_id,
              name: :idx_iep_cpo_on_option_id

    add_foreign_key :iep_curricular_planning_options, :iep_curricular_plannings,
                    column: :iep_curricular_planning_id
    add_foreign_key :iep_curricular_planning_options, :iep_options,
                    column: :iep_option_id
  end
end
