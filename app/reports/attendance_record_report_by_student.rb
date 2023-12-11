class AttendanceRecordReportByStudent < BaseReport

  attr_accessor :start_at, :end_at, :daily_frequencies, :enrollment_classrooms_list,

  def self.build(
    start_at,
    end_at,
    daily_frequencies,
    enrollment_classrooms_list,
    students_frequencies_percentage,
    entity_configuration,
    teacher,
    current_user,
    classroom_id
  )
    new(:landscape).build(
      start_at,
      end_at,
      daily_frequencies,
      enrollment_classrooms_list,
      students_frequencies_percentage,
      entity_configuration,
      teacher,
      current_user,
      classroom_id
    )
  end

  def build(
    start_at,
    end_at,
    daily_frequencies,
    enrollment_classrooms_list,
    students_frequencies_percentage,
    entity_configuration,
    teacher,
    current_user,
    classroom_id
  )
    @start_at = start_at
    @end_at = end_at
    @daily_frequencies = daily_frequencies
    @enrollment_classrooms_list = enrollment_classrooms_list
    @students_frequencies_percentage = students_frequencies_percentage
    @entity_configuration = entity_configuration
    @teacher = set_teacher(teacher, classroom_id, current_user)
  end

  private

  def set_teacher(teacher, classroom_id, current_user)
    return teacher unless current_user.current_role_is_admin_or_employee?
    return teacher if teacher.daily_frequencies.where(classroom_id: classroom_id).any?

    Classroom.find(classroom_id).teacher_discipline_classrooms.first.teacher
  end
end
