class FixDescriptiveExamsIndexes < ActiveRecord::Migration[4.2]
  def change
    remove_index :descriptive_exams, :classroom_id
    remove_index :descriptive_exams, :discipline_id
    remove_index :descriptive_exams, :school_calendar_classroom_step_id
    remove_index :descriptive_exams, :school_calendar_step_id

    add_index :descriptive_exams, :classroom_id, where: "deleted_at IS NULL"
    add_index :descriptive_exams, :discipline_id, where: "deleted_at IS NULL"
    add_index :descriptive_exams, :school_calendar_classroom_step_id, where: "deleted_at IS NULL"
    add_index :descriptive_exams, :school_calendar_step_id, where: "deleted_at IS NULL"
  end
end
