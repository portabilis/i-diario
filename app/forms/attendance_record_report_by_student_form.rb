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

  def select_all_classrooms
    return Classroom.where(id: classroom_id) unless classroom_id.eql?('all')
    return Classroom.by_unity(unity_id).distinct.includes(:grades).order(:id) unless current_user.teacher?

    Classroom.by_unity_and_teacher(unity_id, current_user.teacher_id)
             .includes(:grades)
             .distinct
             .order(:id)
  end

  def enrollment_classrooms_list
    classrooms = select_all_classrooms

    @enrollment_classrooms ||= StudentEnrollmentClassroom
      .includes(student_enrollment: :student)
      .includes(classrooms_grade: :classroom)
      .by_classroom(classroom_id.eql?('all') ? classrooms.map(&:id) : classroom_id)
      .by_date_range(start_at, end_at)
      .by_period(period)
      .where(classrooms_grade: { classrooms: { year: school_calendar_year } })
      .distinct
      .order('classrooms_grades.classroom_id')
      .order('sequence ASC, students.name ASC')

    info_students
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

  def fetch_daily_frequencies
    classrooms = select_all_classrooms

    @daily_frequencies_by_classroom ||= DailyFrequencyQuery.call(
      classroom_id: classroom_id.eql?('all') ? classrooms.map(&:id) : classroom_id,
      period: period,
      frequency_date: start_at..end_at,
      all_students_frequencies: true
    ).order(:classroom_id).group_by(&:classroom_id)
  end

  def calculate_percentage_of_presence
    daily_frequencies = fetch_daily_frequencies

    return if daily_frequencies.blank?

    daily_frequencies.map do |classroom_id, daily_frequencies|
      {
        classroom: classroom_id,
        students: daily_frequencies.flat_map do |daily_frequency|
          daily_frequency.students
        end.group_by(&:student_id).map do |key, daily_frequency_student|
          total_daily_frequency_students = daily_frequency_student.count.to_f
          total_presence = daily_frequency_student.map { |dfs| dfs if dfs.present }.compact.count.to_f
          percentage_frequency = ((total_presence / total_daily_frequency_students) * 100).round(2)

          {
            student_id: daily_frequency_student.first.student_id,
            percentage_frequency: percentage_frequency
          }
        end
      }
    end
  end

  def show_inactive_enrollments
    @show_inactive_enrollments ||= GeneralConfiguration.first.show_inactive_enrollments
  end
end
