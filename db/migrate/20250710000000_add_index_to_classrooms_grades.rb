class AddIndexToClassroomsGrades < ActiveRecord::Migration[5.0]
  disable_ddl_transaction!

  def change
    add_index :classrooms_grades, [:classroom_id, :grade_id], algorithm: :concurrently
  end
end