class AddUsesDifferentiatedExamRuleToUnities < ActiveRecord::Migration[4.2]
  def change
    add_column :unities, :uses_differentiated_exam_rule, :boolean, default: false
  end
end
