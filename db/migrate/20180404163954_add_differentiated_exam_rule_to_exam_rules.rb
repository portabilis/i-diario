class AddDifferentiatedExamRuleToExamRules < ActiveRecord::Migration[4.2]
  def change
    add_column :exam_rules, :differentiated_exam_rule_id, :integer, references: :exam_rules
    add_column :exam_rules, :differentiated_exam_rule_api_code, :string
  end
end
