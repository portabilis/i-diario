class AddAbsenceJustificationStudentIntoDailyFrequencyStudent < ActiveRecord::Migration
  def change
    add_column :daily_frequency_students, :absence_justification_student_id, :integer, null: true
    add_foreign_key :daily_frequency_students, :absence_justifications_students, foreign_key: true, column: :absence_justification_student_id
  end
end
