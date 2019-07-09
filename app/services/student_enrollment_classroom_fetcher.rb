class StudentEnrollmentClassroomFetcher
  def initialize(student, classroom, start_date, end_date)
    @student = student
    @classroom = classroom
    @start_date = start_date
    @end_date = end_date
  end

  def current_enrollment
    @current_enrollment ||= StudentEnrollmentClassroom.by_student(@student)
                                                      .by_classroom(@classroom)
                                                      .by_date_range(@start_date, @end_date)
                                                      .active
                                                      .ordered
                                                      .last
  end

  def previous_enrollments
    StudentEnrollmentClassroom.by_student(@student)
                              .by_classroom(@classroom)
                              .by_date_range(@start_date, @end_date)
                              .where.not(id: current_enrollment.try(:id))
                              .active
  end
end
