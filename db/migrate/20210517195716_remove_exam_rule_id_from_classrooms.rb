class RemoveExamRuleIdFromClassrooms < ActiveRecord::Migration[4.2]
  def change
    remove_column :classrooms, :exam_rule_id
  end
end
