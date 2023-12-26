class AddUniqueIndexToConceptualExams < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!

  def change
    add_index :conceptual_exams, [:classroom_id, :student_id, :step_number],
              name: 'idx_unique_conceptual_exams', unique: true, where: 'discarded_at IS NULL AND NOT old_record',
              algorithm: :concurrently
  end
end
