class AddAbsenceJustificationStudentIntoDailyFrequencyStudent < ActiveRecord::Migration
  def change
    add_column :daily_frequency_students, :absence_justification_student_id, :integer, null: true
  end
end
