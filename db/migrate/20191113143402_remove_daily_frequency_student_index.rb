class RemoveDailyFrequencyStudentIndex < ActiveRecord::Migration
  def change
    remove_index :daily_frequency_students, name: :daily_frequency_students_daily_frequency_id_student_id_idx
  end
end
