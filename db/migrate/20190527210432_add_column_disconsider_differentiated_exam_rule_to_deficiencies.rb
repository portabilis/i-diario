class AddColumnDisconsiderDifferentiatedExamRuleToDeficiencies < ActiveRecord::Migration
  def change
    add_column :deficiencies, :disconsider_differentiated_exam_rule, :boolean, default: false, null: false
  end
end
