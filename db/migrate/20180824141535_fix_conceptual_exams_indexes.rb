class FixConceptualExamsIndexes < ActiveRecord::Migration
  def change
    remove_index :conceptual_exams, :school_calendar_classroom_step_id

    add_index :conceptual_exams, :school_calendar_classroom_step_id, where: "deleted_at IS NULL"
  end
end
