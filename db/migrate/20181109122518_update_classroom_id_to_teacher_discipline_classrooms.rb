class UpdateClassroomIdToTeacherDisciplineClassrooms < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      UPDATE teacher_discipline_classrooms
         SET classroom_id = (
               SELECT classrooms.id
                 FROM classrooms
                WHERE classrooms.api_code = teacher_discipline_classrooms.classroom_api_code
             )
       WHERE teacher_discipline_classrooms.classroom_id IS NULL
         AND teacher_discipline_classrooms.classroom_api_code IS NOT NULL;
    SQL
  end
end
