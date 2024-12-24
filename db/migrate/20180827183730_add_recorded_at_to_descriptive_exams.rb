class AddRecordedAtToDescriptiveExams < ActiveRecord::Migration[4.2]
  def change
    add_column :descriptive_exams, :recorded_at, :date
  end
end
