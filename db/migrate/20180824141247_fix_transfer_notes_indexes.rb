class FixTransferNotesIndexes < ActiveRecord::Migration[4.2]
  def change
    remove_index :transfer_notes, :classroom_id
    remove_index :transfer_notes, :discipline_id
    remove_index :transfer_notes, :school_calendar_classroom_step_id
    remove_index :transfer_notes, :school_calendar_step_id
    remove_index :transfer_notes, :student_id

    add_index :transfer_notes, :classroom_id, where: "deleted_at IS NULL"
    add_index :transfer_notes, :discipline_id, where: "deleted_at IS NULL"
    add_index :transfer_notes, :school_calendar_classroom_step_id, where: "deleted_at IS NULL"
    add_index :transfer_notes, :school_calendar_step_id, where: "deleted_at IS NULL"
    add_index :transfer_notes, :student_id, where: "deleted_at IS NULL"
  end
end
