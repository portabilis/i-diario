class AddStepNumberToConceptualExam < ActiveRecord::Migration[4.2]
  def change
    add_column :conceptual_exams, :step_number, :integer, null: false, default: 0
  end
end
