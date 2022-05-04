class RemoveGradeIdFromClassrooms < ActiveRecord::Migration
  def change
    remove_column :classrooms, :grade_id
  end
end
