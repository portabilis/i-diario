class AttendanceRecordReportByStudentForm
  include ActiveModel::Model

  attr_accessor :unity_id,
                :classroom_id,
                :period,
                :start_at,
                :end_at,
                :school_calendar_year,
                :school_calendar,
                :current_user_id

  validates :start_at, presence: true, date: true, timeliness: {
    on_or_before: :end_at, type: :date, on_or_before_message: I18n.t('errors.messages.on_or_before_message')
  }
  validates :end_at, presence: true, date: true, timeliness: {
    on_or_after: :start_at, type: :date, on_or_after_message: I18n.t('errors.messages.on_or_after_message')
  }
  validates :unity_id, presence: true
  validates :classroom_id, presence: true
  validates :period, presence: true
  validates :school_calendar_year, presence: true
  validates :current_user_id, presence: true
  validates :school_calendar, presence: true

  def filename
    "#{Time.current.to_i}.pdf"
  end

  def unity
    @unity ||= Unity.find(unity_id) if unity_id.present?
  end

  def current_user
    @user ||= User.find(current_user_id) if current_user_id.present?
  end

  def classroom
    @classroom ||= Classroom.find(classroom_id) if classroom_id.present?
  end

  def select_all_classrooms
    return [classroom] unless classroom_id.eql?('all')
    return if unity_id.blank? || current_user.blank?
    return Classroom.by_unity(unity_id).distinct.includes(:grades).order(:id) unless current_user.teacher?

    Classroom.by_unity_and_teacher(unity_id, current_user.teacher_id)
             .includes(:grades)
             .distinct
             .order(:id)
  end

  def info_students_list
    no_students_in_class if enrollment_classrooms.blank?

    info_students
  end

  def enrollment_classrooms
    @enrollment_classrooms ||= StudentEnrollmentClassroom
      .includes(student_enrollment: :student)
      .includes(classrooms_grade: :classroom)
      .by_classroom(select_all_classrooms.map(&:id))
      .by_date_range(start_at, end_at)
      .by_period(adjusted_period)
      .where(classrooms_grade: { classrooms: { year: school_calendar_year } })
      .distinct
      .order('classrooms_grades.classroom_id')
      .order('sequence ASC, students.name ASC')
  end

  def info_students
    @enrollment_classrooms.map do |student_enrollment_classroom|
      student = student_enrollment_classroom.student_enrollment.student
      sequence = student_enrollment_classroom.sequence if @show_inactive_enrollments
      classroom_id = student_enrollment_classroom.classrooms_grade.classroom_id

      {
        student_id: student.id,
        student_name: student.name,
        sequence: sequence,
        classroom_id: classroom_id
      }
    end
  end

  def show_inactive_enrollments
    @show_inactive_enrollments ||= GeneralConfiguration.first.show_inactive_enrollments
  end

  def adjusted_period
    return Periods::FULL if period.eql?('all') || period.eql?(Periods::FULL)
    raise ArgumentError, "Period can't be blank" if period.blank?

    period
  end

  def no_students_in_class
    errors.add(:classroom_id, "Não há alunos enturmados nessa turma no período selecionado")
  end
end
