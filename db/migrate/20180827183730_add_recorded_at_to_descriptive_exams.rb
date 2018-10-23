class AddRecordedAtToDescriptiveExams < ActiveRecord::Migration
  def change
    add_column :descriptive_exams, :recorded_at, :date
  end
end
