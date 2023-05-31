class FixWrongDescriptiveExamsRecordedAt < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      UPDATE descriptive_exams
        SET recorded_at = created_at
      WHERE recorded_at > current_date
    SQL
  end
end
