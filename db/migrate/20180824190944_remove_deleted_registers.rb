class RemoveDeletedRegisters < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      DELETE FROM avaliations WHERE deleted_at IS NOT NULL;

      DELETE FROM conceptual_exam_values WHERE deleted_at IS NOT NULL;

      DELETE FROM conceptual_exams WHERE deleted_at IS NOT NULL;

      DELETE FROM daily_frequencies WHERE deleted_at IS NOT NULL;

      DELETE FROM daily_note_students WHERE deleted_at IS NOT NULL;

      DELETE FROM daily_notes WHERE deleted_at IS NOT NULL;

      DELETE FROM descriptive_exam_students WHERE deleted_at IS NOT NULL;

      DELETE FROM descriptive_exams WHERE deleted_at IS NOT NULL;

      DELETE FROM recovery_diary_record_students WHERE deleted_at IS NOT NULL;

      DELETE FROM recovery_diary_records WHERE deleted_at IS NOT NULL;

      DELETE FROM school_term_recovery_diary_records WHERE deleted_at IS NOT NULL;

      DELETE FROM teacher_discipline_classrooms WHERE deleted_at IS NOT NULL;

      DELETE FROM transfer_notes WHERE deleted_at IS NOT NULL;
    SQL
  end
end
