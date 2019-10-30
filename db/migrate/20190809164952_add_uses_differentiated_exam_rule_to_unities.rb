class AddUsesDifferentiatedExamRuleToUnities < ActiveRecord::Migration
  def change
    add_column :unities, :uses_differentiated_exam_rule, :boolean, default: false
  end
end
