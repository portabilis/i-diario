class FixDescriptiveExamsIndexes2 < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!

  def change
    remove_index :descriptive_exams, column: [:classroom_id], where: "deleted_at IS NULL", algorithm: :concurrently
    remove_index :descriptive_exams, column: [:discipline_id], where: "deleted_at IS NULL", algorithm: :concurrently
    remove_index :descriptive_exams, column: [:school_calendar_classroom_step_id], where: "deleted_at IS NULL", algorithm: :concurrently
    remove_index :descriptive_exams, column: [:school_calendar_step_id], where: "deleted_at IS NULL", algorithm: :concurrently

    add_index :descriptive_exams, :classroom_id, algorithm: :concurrently
    add_index :descriptive_exams, :discipline_id, algorithm: :concurrently
    add_index :descriptive_exams, :school_calendar_classroom_step_id, algorithm: :concurrently
    add_index :descriptive_exams, :school_calendar_step_id, algorithm: :concurrently
  end
end
