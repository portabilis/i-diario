class AddClassroomsGradeIdToLessonsBoard < ActiveRecord::Migration[4.2]
  def change
    add_column :lessons_boards, :classrooms_grade_id, :integer
  end
end
