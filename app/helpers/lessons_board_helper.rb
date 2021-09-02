module LessonsBoardHelper
  def teacher_name_and_discipline(teacher_discipline_classroom_id)
    teacher_discipline = TeacherDisciplineClassroom.find(teacher_discipline_classroom_id)

    teacher_discipline.teacher.name.try(:strip).upcase + ' - ' +
    teacher_discipline.discipline.description.try(:strip).upcase
  end
end
