class FixTransferNotesIndexes2 < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!

  def change
    remove_index :transfer_notes, column: [:classroom_id], where: "deleted_at IS NULL", algorithm: :concurrently
    remove_index :transfer_notes, column: [:discipline_id], where: "deleted_at IS NULL", algorithm: :concurrently
    remove_index :transfer_notes, column: [:school_calendar_classroom_step_id], where: "deleted_at IS NULL", algorithm: :concurrently
    remove_index :transfer_notes, column: [:school_calendar_step_id], where: "deleted_at IS NULL", algorithm: :concurrently
    remove_index :transfer_notes, column: [:student_id], where: "deleted_at IS NULL", algorithm: :concurrently

    add_index :transfer_notes, :classroom_id, algorithm: :concurrently
    add_index :transfer_notes, :discipline_id, algorithm: :concurrently
    add_index :transfer_notes, :school_calendar_classroom_step_id, algorithm: :concurrently
    add_index :transfer_notes, :school_calendar_step_id, algorithm: :concurrently
    add_index :transfer_notes, :student_id, algorithm: :concurrently
  end
end
