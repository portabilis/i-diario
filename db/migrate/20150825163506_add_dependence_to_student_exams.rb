class AddDependenceToStudentExams < ActiveRecord::Migration[4.2]
  def change
    add_column :daily_note_students, :dependence, :boolean
    add_column :daily_frequency_students, :dependence, :boolean
    add_column :conceptual_exam_students, :dependence, :boolean
    add_column :descriptive_exam_students, :dependence, :boolean
  end
end
