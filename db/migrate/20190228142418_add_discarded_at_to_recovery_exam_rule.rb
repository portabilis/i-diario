class AddDiscardedAtToRecoveryExamRule < ActiveRecord::Migration
  def up
    add_column :recovery_exam_rules, :discarded_at, :datetime
    add_index :recovery_exam_rules, :discarded_at
  end

  def down
    remove_column :recovery_exam_rules, :discarded_at
  end
end
