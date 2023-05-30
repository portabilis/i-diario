class SetTeacherIdToAbsenceJustifications < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      update absence_justifications
        set teacher_id = (select users.teacher_id
                            from users
                              where users.id = absence_justifications.author_id) 
    SQL
  end
end
