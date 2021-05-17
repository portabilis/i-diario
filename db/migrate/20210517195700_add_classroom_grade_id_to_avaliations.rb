class AddClassroomGradeIdToAvaliations < ActiveRecord::Migration
  def change
    add_column :avaliations, :classroom_grade_id, :integer
  end
end
