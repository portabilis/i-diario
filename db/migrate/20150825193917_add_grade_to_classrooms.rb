class AddGradeToClassrooms < ActiveRecord::Migration
  def change
    add_column :classrooms, :grade_id, :integer
    add_index :classrooms, :grade_id
    add_foreign_key :classrooms, :grades
  end
end
