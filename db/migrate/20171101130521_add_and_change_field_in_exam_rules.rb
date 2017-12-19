class AddAndChangeFieldInExamRules < ActiveRecord::Migration
  def change
    add_column :exam_rules, :rounding_table_concept_id, :integer, references: :rounding_tables
    add_column :exam_rules, :rounding_table_concept_api_code, :string
  end
end
