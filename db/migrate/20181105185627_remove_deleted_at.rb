class RemoveDeletedAt < ActiveRecord::Migration[4.2]
  def change
    remove_column :teacher_discipline_classrooms, :deleted_at, :datetime

    remove_column :avaliations, :deleted_at, :datetime

    remove_column :daily_notes, :deleted_at, :datetime

    remove_column :daily_note_students, :deleted_at, :datetime

    remove_column :descriptive_exams, :deleted_at, :datetime

    remove_column :descriptive_exam_students, :deleted_at, :datetime

    remove_column :transfer_notes, :deleted_at, :datetime

    remove_column :conceptual_exams, :deleted_at, :datetime

    remove_column :conceptual_exam_values, :deleted_at, :datetime

    remove_column :recovery_diary_records, :deleted_at, :datetime

    remove_column :recovery_diary_record_students, :deleted_at, :datetime

    remove_column :school_term_recovery_diary_records, :deleted_at, :datetime

    remove_column :daily_frequencies, :deleted_at, :datetime
  end
end
