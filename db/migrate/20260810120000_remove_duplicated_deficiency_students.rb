# Remove as cópias de vínculo entre aluno e deficiência geradas pelo sincronizador, mantendo
# para cada aluno/deficiência/escola o registro ativo mais antigo (ou o mais antigo
# descartado, quando não houver nenhum ativo).
class RemoveDuplicatedDeficiencyStudents < ActiveRecord::Migration[5.0]
  def up
    execute <<-SQL
      DELETE FROM deficiency_students deficiency_student
      USING (
        SELECT id,
               row_number() OVER (
                 PARTITION BY student_id, deficiency_id, COALESCE(unity_id, 0)
                 ORDER BY (discarded_at IS NOT NULL), id
               ) AS position
        FROM deficiency_students
      ) duplicated
      WHERE deficiency_student.id = duplicated.id
        AND duplicated.position > 1
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
