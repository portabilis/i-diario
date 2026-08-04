class AddClassroomIdToIepVersions < ActiveRecord::Migration[5.0]
  # Registra a turma que publicou cada versão (autoria). É o que torna a visibilidade/congelamento
  # do PEI imunes a data de transferência retroativa: quem lançou algo continua enxergando o que
  # lançou, independentemente do left_at da matrícula. Nulo nas versões legadas (feature nova).
  def change
    add_column :iep_versions, :classroom_id, :integer
    add_index :iep_versions, :classroom_id
    add_foreign_key :iep_versions, :classrooms, column: :classroom_id
  end
end
