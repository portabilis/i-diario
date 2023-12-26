class AddCalculateAvgParallelExamsToExamRules < ActiveRecord::Migration[4.2]
  def change
    add_column :exam_rules, :calculate_avg_parallel_exams, :boolean, null: false, default: false
  end
end
