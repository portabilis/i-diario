class CreateTeacherUnificationTeachers < ActiveRecord::Migration[4.2]
  def change
    create_table :teacher_unification_teachers do |t|
      t.belongs_to :teacher_unification
      t.belongs_to :teacher
      t.timestamps
    end
  end
end
