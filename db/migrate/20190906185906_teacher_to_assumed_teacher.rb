class TeacherToAssumedTeacher < ActiveRecord::Migration[4.2]
  def up
    execute <<-SQL
      UPDATE users
      SET assumed_teacher_id = teacher_id
      WHERE teacher_id IS NOT NULL
    SQL
  end

  def down
    execute <<-SQL
      UPDATE users
      SET assumed_teacher_id = NULL
      WHERE teacher_id IS NOT NULL
    SQL
  end
end
