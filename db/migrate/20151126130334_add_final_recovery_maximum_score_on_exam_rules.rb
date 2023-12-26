class AddFinalRecoveryMaximumScoreOnExamRules < ActiveRecord::Migration[4.2]
  def change
    add_column :exam_rules, :final_recovery_maximum_score, :integer

    execute <<-SQL
      UPDATE exam_rules SET final_recovery_maximum_score = 0 WHERE final_recovery_maximum_score IS NULL;
    SQL

    change_column :exam_rules, :final_recovery_maximum_score, :integer, null: false
  end
end
