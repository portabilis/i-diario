class ChangeDailyFrequencyStudentIndexToWhereDiscardedAtIsNull < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!

  def change
    add_index :daily_frequency_students, [:daily_frequency_id, :student_id],
              name: :idx_daily_frequency_students_daily_frequency_id_student_id, unique: true,
              where: 'discarded_at IS NULL', algorithm: :concurrently
  end
end
