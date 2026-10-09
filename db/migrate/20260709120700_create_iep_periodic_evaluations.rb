class CreateIepPeriodicEvaluations < ActiveRecord::Migration[5.0]
  def change
    create_table :iep_periodic_evaluations do |t|
      t.integer :individualized_educational_plan_id, null: false
      t.integer :discipline_id                        # "Por Disciplina" (nullable)
      t.integer :knowledge_area_id                    # "Por Campo de Experiência" (nullable)
      t.integer :iep_review_date_id, null: false      # revisão (1ª, 2ª...) a que a avaliação pertence
      t.text :acquired_skills
      t.text :in_progress_skills
      t.text :not_acquired_skills
      t.text :period_report
      t.text :next_stage_adjustments

      t.timestamps
    end

    add_index :iep_periodic_evaluations, :individualized_educational_plan_id,
              name: :idx_iep_pe_on_iep
    add_index :iep_periodic_evaluations, :discipline_id
    add_index :iep_periodic_evaluations, :knowledge_area_id
    add_index :iep_periodic_evaluations, :iep_review_date_id

    # Um componente (disciplina OU campo de experiência) só pode aparecer uma vez por revisão.
    # Índices parciais porque as colunas são mutuamente exclusivas (XOR do CHECK abaixo).
    add_index :iep_periodic_evaluations, [:iep_review_date_id, :discipline_id],
              unique: true, where: 'discipline_id IS NOT NULL', name: :idx_iep_pe_unique_discipline
    add_index :iep_periodic_evaluations, [:iep_review_date_id, :knowledge_area_id],
              unique: true, where: 'knowledge_area_id IS NOT NULL', name: :idx_iep_pe_unique_knowledge_area

    add_foreign_key :iep_periodic_evaluations, :individualized_educational_plans,
                    column: :individualized_educational_plan_id
    add_foreign_key :iep_periodic_evaluations, :disciplines
    add_foreign_key :iep_periodic_evaluations, :knowledge_areas
    add_foreign_key :iep_periodic_evaluations, :iep_review_dates

    # Exatamente um: disciplina OU área de conhecimento (torna o estado ilegal irrepresentável)
    reversible do |dir|
      dir.up do
        execute <<~SQL
          ALTER TABLE iep_periodic_evaluations
          ADD CONSTRAINT chk_iep_pe_component
          CHECK ((discipline_id IS NULL) <> (knowledge_area_id IS NULL))
        SQL
      end
      dir.down do
        execute 'ALTER TABLE iep_periodic_evaluations DROP CONSTRAINT chk_iep_pe_component'
      end
    end
  end
end
