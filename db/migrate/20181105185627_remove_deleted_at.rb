class RemoveDeletedAt < ActiveRecord::Migration
  def change
    remove_index :teacher_discipline_classrooms, :deleted_at
    remove_column :teacher_discipline_classrooms, :deleted_at, :datetime

    remove_index :avaliations, :deleted_at
    remove_column :avaliations, :deleted_at, :datetime

    remove_index :daily_notes, :deleted_at
    remove_column :daily_notes, :deleted_at, :datetime

    remove_index :daily_note_students, :deleted_at
    remove_column :daily_note_students, :deleted_at, :datetime

    remove_index :descriptive_exams, :deleted_at
    remove_column :descriptive_exams, :deleted_at, :datetime

    remove_index :descriptive_exam_students, :deleted_at
    remove_column :descriptive_exam_students, :deleted_at, :datetime

    remove_index :transfer_notes, :deleted_at
    remove_column :transfer_notes, :deleted_at, :datetime

    remove_index :conceptual_exams, :deleted_at
    remove_column :conceptual_exams, :deleted_at, :datetime

    remove_index :conceptual_exam_values, :deleted_at
    remove_column :conceptual_exam_values, :deleted_at, :datetime

    remove_index :recovery_diary_records, :deleted_at
    remove_column :recovery_diary_records, :deleted_at, :datetime

    remove_index :recovery_diary_record_students, :deleted_at
    remove_column :recovery_diary_record_students, :deleted_at, :datetime

    remove_index :school_term_recovery_diary_records, :deleted_at
    remove_column :school_term_recovery_diary_records, :deleted_at, :datetime

    remove_index :daily_frequencies, :deleted_at
    remove_column :daily_frequencies, :deleted_at, :datetime
  end
end
