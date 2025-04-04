class TeacherPeriodFetcher
  def initialize(teacher_id, classroom_id, discipline_id)
    @teacher_id = teacher_id
    @classroom_id = classroom_id
    @discipline_id = discipline_id
  end

  def teacher_period
    return classroom_period if @teacher_id.blank?

    grade_ids = ClassroomsGrade.where(classroom_id: @classroom_id).map(&:grade)

    teacher_discipline_classrooms = TeacherDisciplineClassroom.where(
      teacher_id: @teacher_id,
      classroom_id: @classroom_id,
      grade_id: grade_ids
    )

    if @discipline_id
      teacher_discipline_classrooms = teacher_discipline_classrooms.where(discipline_id: @discipline_id)
    end

    teacher_discipline_classrooms.first.try(:period) || classroom_period
  end

  def classroom_period
    @classroom_period ||= Classroom.find_by(id: @classroom_id)&.period.to_i
  end
end
