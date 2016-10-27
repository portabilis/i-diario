class StudentsFetcher
  def initialize(classroom, discipline = nil, date = Time.zone.today, start_date = nil)
    @classroom = classroom
    @discipline = discipline
    @date = date
    @start_date = start_date
  end

  def fetch
    student_enrollments = StudentEnrollment
      .by_classroom(@classroom)
      .by_date(@date)

    if @start_date
      student_enrollments = student_enrollments
        .by_date_not_before(@start_date.to_date)
    end

    student_ids = student_enrollments.ordered.collect(&:student_id)

    Student.where(id: student_ids)
  end
end
