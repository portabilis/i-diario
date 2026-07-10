class CreateIndividualizedEducationalPlans < ActiveRecord::Migration[5.0]
  def change
    create_table :individualized_educational_plans do |t|
      # Seção 1 — Identificação
      t.integer :student_id, null: false
      t.integer :unity_id, null: false
      t.integer :classroom_id, null: false
      t.integer :teacher_id, null: false          # professor regente (único, da turma)
      t.integer :aee_teacher_id                    # professor de AEE (opcional)
      t.integer :year, null: false
      t.string :support_professional               # profissional de apoio / cuidador
      t.date :elaborated_at, null: false
      t.datetime :finalized_at                     # cache; a verdade de finalizado é a existência de versão ativa

      # Seção 2 — Caracterização do Estudante
      t.text :characterization
      t.text :clinical_diagnosis_justification
      t.text :school_history
      t.text :potentialities
      t.text :difficulties
      t.text :preferences_interests
      t.text :effective_strategies

      # Seção 3 — Equipe de suporte
      t.text :family_guidelines
      t.text :external_professionals_guidelines

      # Seção 6 — Avaliação Final
      t.text :annual_report
      t.text :overall_evolution
      t.text :next_year_recommendations
      t.text :referrals_made

      t.timestamps
    end

    add_index :individualized_educational_plans, :classroom_id, name: :idx_iep_on_classroom_id
    add_index :individualized_educational_plans, :unity_id, name: :idx_iep_on_unity_id
    # Índice único: 1 PEI por aluno/ano (a transferência move o registro, não cria outro).
    # O índice composto também cobre buscas só por student_id (prefixo à esquerda).
    add_index :individualized_educational_plans, [:student_id, :year],
              unique: true, name: :idx_iep_on_student_id_and_year

    add_foreign_key :individualized_educational_plans, :students
    add_foreign_key :individualized_educational_plans, :unities
    add_foreign_key :individualized_educational_plans, :classrooms
    add_foreign_key :individualized_educational_plans, :teachers, column: :teacher_id
    add_foreign_key :individualized_educational_plans, :teachers, column: :aee_teacher_id
  end
end
