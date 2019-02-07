class TeacherPeriodFetcher
  def initialize(teacher_id, classroom_id, discipline_id)
    @teacher_id = teacher_id
    @classroom_id = classroom_id
    @discipline_id = discipline_id
  end

  def teacher_period
    TeacherDisciplineClassroom.find_by(
      teacher_id: @teacher_id,
      classroom_id: @classroom_id,
      discipline_id: @discipline_id
    ).period || Classroom.find(@classroom_id).period.to_i
  end
end
