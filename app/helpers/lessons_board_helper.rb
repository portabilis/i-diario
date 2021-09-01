module LessonsBoardHelper
  def teacher_name_by_teacher_discipline_classroom(teacher_discipline_classroom_id)
    teacher_discipline = TeacherDisciplineClassroom.find(teacher_discipline_classroom_id)

    teacher_discipline.teacher.name.try(:strip).upcase + ' - ' +
    teacher_discipline.discipline.description.try(:strip).upcase
  end
end
