class RemoveContextColumnsFromIndividualizedEducationalPlans < ActiveRecord::Migration[5.0]
  # O PEI passa a seguir o aluno: escola/turma/regente deixam de ser propriedade do documento
  # e são derivados da matrícula atual. Só o AEE (escolhido) permanece no plano.
  def change
    remove_column :individualized_educational_plans, :unity_id, :integer
    remove_column :individualized_educational_plans, :classroom_id, :integer
    remove_column :individualized_educational_plans, :teacher_id, :integer
  end
end
