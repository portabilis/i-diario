class AddExemptedDisciplineToConceptualExamValues < ActiveRecord::Migration
  def change
    add_column :conceptual_exam_values, :exempted_discipline, :boolean, default: false
  end
end
