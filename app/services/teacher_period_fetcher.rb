class TeacherPeriodFetcher
  def initialize(teacher_id, classroom_id, discipline_id)
    @teacher_id = teacher_id
    @classroom_id = classroom_id
    @discipline_id = discipline_id
  end

  def teacher_period
    period = if @teacher_id
               TeacherDisciplineClassroom.find_by(
                 teacher_id: @teacher_id,
                 classroom_id: @classroom_id,
                 discipline_id: @discipline_id
               ).period
             end

    period || Classroom.find(@classroom_id).period.to_i
  end
end
