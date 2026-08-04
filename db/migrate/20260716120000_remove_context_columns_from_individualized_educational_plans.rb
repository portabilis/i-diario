class RemoveContextColumnsFromIndividualizedEducationalPlans < ActiveRecord::Migration[5.0]
  # O PEI passa a seguir o aluno: escola/turma/regente deixam de ser propriedade do documento
  # e são derivados da matrícula atual. Só o AEE (escolhido) permanece no plano.
  def change
    remove_index :individualized_educational_plans, name: :idx_iep_on_classroom_id
    remove_index :individualized_educational_plans, name: :idx_iep_on_unity_id

    remove_column :individualized_educational_plans, :unity_id, :integer
    remove_column :individualized_educational_plans, :classroom_id, :integer
    remove_column :individualized_educational_plans, :teacher_id, :integer
  end
end
