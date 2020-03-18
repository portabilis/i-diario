class AddUniqueIndexToUniqueDailyFrequencyStudents < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    add_index :unique_daily_frequency_students, [:student_id, :classroom_id, :frequency_date],
              name: 'idx_unique_daily_frequency_students', unique: true, algorithm: :concurrently
  end
end
