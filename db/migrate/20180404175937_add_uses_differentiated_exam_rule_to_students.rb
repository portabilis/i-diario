class AddUsesDifferentiatedExamRuleToStudents < ActiveRecord::Migration[4.2]
  def change
    add_column :students, :uses_differentiated_exam_rule, :boolean, null: false, default: false
  end
end
