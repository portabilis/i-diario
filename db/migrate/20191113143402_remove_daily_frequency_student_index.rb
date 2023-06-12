class RemoveDailyFrequencyStudentIndex < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!

  def change
    remove_index :daily_frequency_students, name: :daily_frequency_students_daily_frequency_id_student_id_idx,
                 algorithm: :concurrently
  end
end
