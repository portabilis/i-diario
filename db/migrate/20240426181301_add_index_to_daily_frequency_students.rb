class AddIndexToDailyFrequencyStudents < ActiveRecord::Migration[5.0]
  def change
    add_index :daily_frequency_students, :absence_justification_student_id,
              name: 'index_daily_frequency_students_absence_justifications'
  end
end
