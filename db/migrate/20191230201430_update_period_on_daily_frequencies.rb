class UpdatePeriodOnDailyFrequencies < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      UPDATE daily_frequencies
         SET period = CAST(classrooms.period AS INTEGER)
        FROM classrooms
       WHERE daily_frequencies.classroom_id = classrooms.id
         AND daily_frequencies.period <> CAST(classrooms.period AS INTEGER)
         AND classrooms.period IS NOT NULL
         AND CAST(classrooms.period AS INTEGER) <> 4
         AND NOT EXISTS (
           SELECT 1
             FROM daily_frequencies AS _daily_frequencies
            WHERE _daily_frequencies.classroom_id = daily_frequencies.classroom_id
              AND _daily_frequencies.frequency_date = daily_frequencies.frequency_date
              AND _daily_frequencies.period = CAST(classrooms.period AS INTEGER)
         )
    SQL
  end
end
