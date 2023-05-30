class MigrateCalculateAvgParallelExamsToParallelExamsCalculationType < ActiveRecord::Migration[4.2]
  def up
    add_column :exam_rules, :parallel_exams_calculation_type, :integer, null: false, default: 1

    execute <<-SQL
      UPDATE exam_rules
      SET parallel_exams_calculation_type = CASE
        WHEN calculate_avg_parallel_exams THEN 2
        ELSE 1
      END
    SQL

    remove_column :exam_rules, :calculate_avg_parallel_exams
  end

  def down
    add_column :exam_rules, :calculate_avg_parallel_exams, :boolean, null: false, default: false

    execute <<-SQL
      UPDATE exam_rules
      SET calculate_avg_parallel_exams = CASE
        WHEN parallel_exams_calculation_type = 2 THEN true
        ELSE false
      END
    SQL

    remove_column :exam_rules, :parallel_exams_calculation_type
  end
end
