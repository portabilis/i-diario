class AddExamRuleToClassroom < ActiveRecord::Migration[4.2]
  def change
    add_column :classrooms, :exam_rule_id, :integer, index: true
    add_foreign_key :classrooms, :exam_rules
  end
end
