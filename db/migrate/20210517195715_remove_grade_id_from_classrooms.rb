class RemoveGradeIdFromClassrooms < ActiveRecord::Migration[4.2]
  def change
    remove_column :classrooms, :grade_id
  end
end
