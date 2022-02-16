class AddClassroomsGradeIdToLessonsBoard < ActiveRecord::Migration
  def change
    add_column :lessons_boards, :classrooms_grade_id, :integer
  end
end
