class StudentsFetcher
  def initialize(classroom, discipline = nil, date = Time.zone.today, start_date = nil, score_type = 'both')
    @classroom = classroom
    @discipline = discipline
    @date = date
    @start_date = start_date
    @score_type = score_type
  end

  def fetch
    student_enrollments = StudentEnrollment
      .by_classroom(@classroom)
      .by_discipline(@discipline)
      .by_date(@date)
      .by_score_type(@score_type, @classroom)
      .active

    if @start_date
      student_enrollments = student_enrollments
        .by_date_not_before(@start_date.to_date)
    end

    student_ids = student_enrollments.ordered.collect(&:student_id)

    Student.where(id: student_ids)
  end
end
