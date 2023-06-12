class RemoveClassroomIdFromLessonsBoard < ActiveRecord::Migration[4.2]
  def change
    remove_column :lessons_boards, :classroom_id
  end
end
