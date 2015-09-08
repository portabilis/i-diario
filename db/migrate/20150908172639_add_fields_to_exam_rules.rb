class AddFieldsToExamRules < ActiveRecord::Migration
  def change
    add_column :exam_rules, :recovery_type, :integer
    add_column :exam_rules, :parallel_recovery_average, :decimal
  end
end
