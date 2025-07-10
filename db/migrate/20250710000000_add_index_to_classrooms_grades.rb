class AddIndexToClassroomsGrades < ActiveRecord::Migration[5.0]
  def change
    add_index :classrooms_grades, [:classroom_id, :grade_id]
  end
end