class ParentDashboardStudentsQuery
  def initialize(user, date)
    @user = user
    @date = date
  end

  def student_enrollment_classrooms
    StudentEnrollmentClassroom.joins(student_enrollment: { student: :users })
                              .joins(classrooms_grade: :classroom)
                              .by_date(date)
                              .where(User.arel_table[:id].eq(user.id))
                              .merge(StudentEnrollment.active)
                              .merge(Classroom.by_year(date.year))
                              .merge(Student.ordered)
  end

  private

  attr_accessor :user, :date
end
