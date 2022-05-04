class RemoveClassroomIdFromLessonsBoard < ActiveRecord::Migration
  def change
    remove_column :lessons_boards, :classroom_id
  end
end
