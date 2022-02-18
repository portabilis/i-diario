class CreateClassroomsGrades < ActiveRecord::Migration
  def change
    create_table :classrooms_grades do |t|
      t.belongs_to :classroom
      t.belongs_to :grade
      t.belongs_to :exam_rule
      t.timestamps
    end
  end
end
