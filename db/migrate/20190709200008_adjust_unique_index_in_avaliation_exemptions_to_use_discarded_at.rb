class AdjustUniqueIndexInAvaliationExemptionsToUseDiscardedAt < ActiveRecord::Migration[4.2]
  def change
    execute 'DROP INDEX IF EXISTS index_avaliation_exemptions_on_avaliation_id_and_student_id'
    add_index :avaliation_exemptions, [:avaliation_id, :student_id, :discarded_at],
              name: 'unique_idx_avaliation_exemptions_on_avaliation_and_student', unique: true
  end
end
