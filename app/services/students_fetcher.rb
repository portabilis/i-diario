class StudentsFetcher
  def initialize(classroom, discipline = nil, date = Time.zone.today, start_date = nil, score_type = StudentEnrollmentScoreTypeFilters::BOTH, step_number = nil)
    @classroom = classroom
    @discipline = discipline
    @date = date
    @start_date = start_date
    @score_type = score_type
    @step_number = step_number
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

    students = Student.where(id: student_ids)

    if @discipline.present? && @step_number.present?
      students.each do |student|
        student_enrollment = student_enrollments.find_by_student_id(student.id)
        exempted_from_discipline = student_enrollment.exempted_disciplines.by_discipline(@discipline.id)
                                                                          .by_step_number(@step_number)
                                                                          .any?
        student.exempted_from_discipline = exempted_from_discipline
      end
    end

    students
  end
end
