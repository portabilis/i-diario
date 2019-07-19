class AddCalculateAvgParallelExamsToExamRules < ActiveRecord::Migration
  def change
    add_column :exam_rules, :calculate_avg_parallel_exams, :boolean, null: false, default: false
  end
end
