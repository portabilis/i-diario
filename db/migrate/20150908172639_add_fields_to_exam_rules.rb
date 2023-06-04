class AddFieldsToExamRules < ActiveRecord::Migration[4.2]
  def change
    add_column :exam_rules, :recovery_type, :integer
    add_column :exam_rules, :parallel_recovery_average, :decimal
  end
end
