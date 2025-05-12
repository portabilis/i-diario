class RemoveDuplicatedApiCodeTeacherDisciplineClassrooms < ActiveRecord::Migration[4.2]
  def change
    teacher_discipline_classrooms = TeacherDisciplineClassroom.unscoped.group(
      :api_code, :teacher_id, :year, :discipline_id
    ).having(
      'COUNT(1) > 1'
    ).pluck(
      'MAX(id)', :api_code, :teacher_id, :year, :discipline_id
    )

    teacher_discipline_classrooms.each do |correct_id, api_code, teacher_id, year, discipline_id|
      TeacherDisciplineClassroom.unscoped.where(
        api_code: api_code,
        teacher_id: teacher_id,
        year: year,
        discipline_id: discipline_id
      ).where.not(id: correct_id).delete_all
    end
  end
end
