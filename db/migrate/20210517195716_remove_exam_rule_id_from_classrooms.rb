class RemoveExamRuleIdFromClassrooms < ActiveRecord::Migration
  def change
    remove_column :classrooms, :exam_rule_id
  end
end
