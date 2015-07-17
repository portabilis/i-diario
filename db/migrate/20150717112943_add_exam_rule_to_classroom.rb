class AddExamRuleToClassroom < ActiveRecord::Migration
  def change
    add_column :classrooms, :exam_rule_id, :integer, index: true
    add_foreign_key :classrooms, :exam_rules
  end
end
