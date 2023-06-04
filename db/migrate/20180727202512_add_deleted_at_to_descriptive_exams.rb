class AddDeletedAtToDescriptiveExams < ActiveRecord::Migration[4.2]
  def change
    add_column :descriptive_exams, :deleted_at, :datetime
    add_index :descriptive_exams, :deleted_at
  end
end
