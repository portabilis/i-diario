class TeacherRegentFetcher
  def initialize(classroom_id, year)
    @classroom_id = classroom_id
    @year = year
  end

  def teacher_regent
    return if @classroom_id.blank?

    regent_teacher = TeacherDisciplineClassroom.by_classroom(@classroom_id)
                                               .by_year(@year)
                                               .where(allow_absence_by_discipline: 0)
                                               .first.try(:teacher)

    regent_teacher
  end

end
