class FixConceptualExamsIndexes2 < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!

  def change
    remove_index :conceptual_exams, column: [:school_calendar_classroom_step_id], where: "deleted_at IS NULL", algorithm: :concurrently

    add_index :conceptual_exams, :school_calendar_classroom_step_id, algorithm: :concurrently
  end
end
