class AddDiscardedAtToIndividualizedEducationalPlans < ActiveRecord::Migration[5.0]
  def up
    add_column :individualized_educational_plans, :discarded_at, :datetime
    add_index :individualized_educational_plans, :discarded_at, name: :idx_iep_on_discarded_at

    # A unicidade de 1 PEI por aluno/ano vale só entre os planos vivos: no índice total o plano
    # arquivado continuaria ocupando o par (student_id, year) e impediria criar outro para o mesmo
    # aluno no mesmo ano. O filtro precisa ser WHERE parcial — pôr discarded_at no corpo do índice
    # não resolve, porque o Postgres trata NULLs como distintos e deixaria passar dois planos vivos.
    remove_index :individualized_educational_plans, name: :idx_iep_on_student_id_and_year
    add_index :individualized_educational_plans, [:student_id, :year],
              unique: true, where: 'discarded_at IS NULL', name: :idx_iep_on_student_id_and_year
  end

  def down
    # Recriar o índice total falha se houver plano arquivado com o mesmo aluno/ano de um vivo —
    # o rollback exige decidir o que fazer com esses registros antes.
    remove_index :individualized_educational_plans, name: :idx_iep_on_student_id_and_year
    add_index :individualized_educational_plans, [:student_id, :year],
              unique: true, name: :idx_iep_on_student_id_and_year

    remove_index :individualized_educational_plans, name: :idx_iep_on_discarded_at
    remove_column :individualized_educational_plans, :discarded_at
  end
end
