class AddExemptedDisciplineToConceptualExamValues < ActiveRecord::Migration[4.2]
  def change
    add_column :conceptual_exam_values, :exempted_discipline, :boolean, default: false
  end
end
