class CreateIepCurricularPlannings < ActiveRecord::Migration[5.0]
  def change
    create_table :iep_curricular_plannings do |t|
      t.integer :individualized_educational_plan_id, null: false
      t.integer :discipline_id                        # "Por Disciplina" (nullable)
      t.integer :knowledge_area_id                    # "Por Campo de Experiência" (nullable)
      t.integer :school_term_type_step_id             # etapa (null = anual)
      t.text :long_term_goal
      t.text :stage_objectives
      t.text :skills_to_develop
      t.text :methodologies

      t.timestamps
    end

    add_index :iep_curricular_plannings, :individualized_educational_plan_id,
              name: :idx_iep_cp_on_iep
    add_index :iep_curricular_plannings, :discipline_id
    add_index :iep_curricular_plannings, :knowledge_area_id

    add_foreign_key :iep_curricular_plannings, :individualized_educational_plans,
                    column: :individualized_educational_plan_id
    add_foreign_key :iep_curricular_plannings, :disciplines
    add_foreign_key :iep_curricular_plannings, :knowledge_areas
    add_foreign_key :iep_curricular_plannings, :school_term_type_steps

    # Exatamente um: disciplina OU área de conhecimento (torna o estado ilegal irrepresentável)
    reversible do |dir|
      dir.up do
        execute <<~SQL
          ALTER TABLE iep_curricular_plannings
          ADD CONSTRAINT chk_iep_cp_component
          CHECK ((discipline_id IS NULL) <> (knowledge_area_id IS NULL))
        SQL
      end
      dir.down do
        execute 'ALTER TABLE iep_curricular_plannings DROP CONSTRAINT chk_iep_cp_component'
      end
    end
  end
end
