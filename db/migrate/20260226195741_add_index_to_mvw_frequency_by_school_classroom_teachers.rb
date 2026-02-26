class AddIndexToMvwFrequencyBySchoolClassroomTeachers < ActiveRecord::Migration[5.0]
  disable_ddl_transaction!

  def up
    execute <<~SQL
      CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_mvw_freq_unity_date 
      ON mvw_frequency_by_school_classroom_teachers (unity_id, frequency_date);
    SQL
  end

  def down
    execute <<~SQL
      DROP INDEX CONCURRENTLY IF NOT EXISTS idx_mvw_freq_unity_date;
    SQL
  end
end
