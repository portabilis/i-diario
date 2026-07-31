class AddRegentApiCodeToClassrooms < ActiveRecord::Migration[5.0]
  def change
    # Código (i-Educar) do servidor definido como professor regente da turma.
    # Já vem no resource turmas-por-escola (ref_cod_regente); passa a ser sincronizado.
    add_column :classrooms, :regent_api_code, :string
  end
end
