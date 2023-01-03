class DisciplineTeachersFetcher
  def initialize(discipline, classroom)
    @classroom = classroom
    @discipline = discipline
  end

  def teachers_by_classroom
    @discipline.teacher_discipline_classrooms
               .by_classroom(@classroom)
               .pluck(:teacher_id)
               .uniq
  end
end
