class AddDiscardedAtToIndividualizedEducationalPlans < ActiveRecord::Migration[5.0]
  DUPLICATED_PAIRS_SQL = <<~SQL.freeze
    SELECT COUNT(*) FROM (
      SELECT student_id, year
      FROM individualized_educational_plans
      GROUP BY student_id, year
      HAVING COUNT(*) > 1
    ) pares
  SQL

  def up
    add_column :individualized_educational_plans, :discarded_at, :datetime

    # A unicidade de 1 PEI por aluno/ano vale só entre os planos vivos: no índice total o plano
    # arquivado continuaria ocupando o par (student_id, year) e impediria criar outro para o mesmo
    # aluno no mesmo ano. O filtro precisa ser WHERE parcial — pôr discarded_at no corpo do índice
    # não resolve, porque o Postgres trata NULLs como distintos e deixaria passar dois planos vivos.
    remove_index :individualized_educational_plans, name: :idx_iep_on_student_id_and_year
    add_index :individualized_educational_plans, [:student_id, :year],
              unique: true, where: 'discarded_at IS NULL', name: :idx_iep_on_student_id_and_year
  end

  # Duas restrições que o rollback não consegue contornar sozinho, e por isso ele para antes de
  # gravar qualquer coisa:
  #   - o índice total não aceita mais de um plano por aluno/ano, e o arquivamento cria esse estado
  #     (arquivar e recriar, ou arquivar os dois) — sem plano vivo em duplicidade que seja;
  #   - remover a coluna faz todo plano arquivado voltar a contar como vivo, ressuscitando em
  #     silêncio registros que o usuário tirou da listagem.
  def down
    duplicated = select_value(DUPLICATED_PAIRS_SQL).to_i

    if duplicated.positive?
      raise ActiveRecord::IrreversibleMigration,
            "#{duplicated} par(es) aluno/ano com mais de um plano nesta base: resolva esses " \
            'registros antes de recriar o índice único total.'
    end

    remove_index :individualized_educational_plans, name: :idx_iep_on_student_id_and_year
    add_index :individualized_educational_plans, [:student_id, :year],
              unique: true, name: :idx_iep_on_student_id_and_year

    remove_column :individualized_educational_plans, :discarded_at
  end
end
