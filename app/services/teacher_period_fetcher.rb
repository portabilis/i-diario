class TeacherPeriodFetcher
  def initialize(teacher_id, classroom_id, discipline_id)
    @teacher_id = teacher_id
    @classroom_id = classroom_id
    @discipline_id = discipline_id
  end

  def teacher_period
    return Classroom.find(@classroom_id).period.to_i if @teacher_id.blank?

    teacher_discipline_classrooms = TeacherDisciplineClassroom.where(
      teacher_id: @teacher_id,
      classroom_id: @classroom_id
    )

    if @discipline_id
      teacher_discipline_classrooms = teacher_discipline_classrooms.where(discipline_id: @discipline_id)
    end

    teacher_discipline_classrooms.first.try(:period)
  end
end
