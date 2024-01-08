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

  def unity
    unity = Unity.find(unity_id) if unity_id.present?
  end

  def current_user
    user = User.find(current_user_id) if current_user_id.present?
  end

  def select_all_classrooms
    return classroom_id unless classroom_id.eql?('all')
    return Classroom.by_unity(unity_id).distinct.includes(:grades).order(:id) unless current_user.teacher?

    Classroom.by_unity_and_teacher(unity_id, current_user.teacher_id)
             .includes(:grades)
             .distinct
             .order(:id)
  end

  def adjusted_period
    return if period.eql?('all') || period.eql?(Periods::FULL)

    period
  end

  def fetch_daily_frequencies
    classrooms = select_all_classrooms

    @daily_frequencies = DailyFrequencyQuery.call(
      classroom_id: classroom_id.eql?('all') ? classrooms.map(&:id) : classroom_id,
      period: adjusted_period,
      frequency_date: start_at..end_at,
      all_students_frequencies: true
    ).order(:classroom_id)
  end

  def enrollment_classrooms_list
    classrooms = select_all_classrooms

    @enrollment_classrooms_list = StudentEnrollmentClassroom
      .includes(student_enrollment: :student)
      .includes(classrooms_grade: :classroom)
      .by_classroom(classroom_id.eql?('all') ? classrooms.map(&:id) : classroom_id)
      .by_date_range(start_at, end_at)
      .by_period(adjusted_period)
      .distinct
      .order('classrooms_grades.classroom_id')
    return unless unity_id.present?

    unity ||= Unity.find(unity_id)
  end

  def current_user
    return unless current_user_id.present?

    user ||= User.find(current_user_id)
  end

  def set_grades
    return unless classroom_id.eql?('all')

    classroom_ids = set_all_classrooms
    grades ||= ClassroomsGrade.includes(:grade)
                              .by_classroom_id(classroom_ids)
                              .map(&:grade)
                              .uniq
  end

  def set_all_classrooms
    return classroom_id unless classroom_id.eql?('all')
    return Classroom.by_unity(unity_id).distinct unless current_user.teacher?

    Classroom.by_unity_and_teacher(unity_id, current_user.teacher_id).distinct
  end

  def fetch_daily_frequencies
    classroom_id = set_all_classrooms

    @daily_frequencies ||= DailyFrequencyQuery.call(
      classroom_id: classroom_id.map(&:id),
      period: period,
      frequency_date: start_at..end_at,
      all_students_frequencies: true
    ).order(:owner_teacher_id)
  end

  def enrollment_classrooms_list
    adjusted_period = period != Periods::FULL ? period : nil
    classroom_id = set_all_classrooms

    @enrollment_classrooms_list ||= StudentEnrollmentClassroomsRetriever.call(
      classrooms: classroom_id,
      disciplines: nil,
      start_at: start_at,
      end_at: end_at,
      search_type: :by_date_range,
      show_inactive: false,
      period: adjusted_period
    )
  end

  def students_frequencies_percentage
    percentage_by_student = Hash.new(0)
    daily_frequency_by_student = Hash.new { |hash, key| hash[key] = Set.new }

    fetch_daily_frequencies.flat_map(&:students).each do |daily_frequency_student|
      student_id = daily_frequency_student.student_id
      frequency_date = daily_frequency_student.daily_frequency.frequency_date

      next if daily_frequency_by_student[student_id].include?(frequency_date)

      percentage_by_student[student_id] ||= 0
      percentage_by_student[student_id] += 1 unless daily_frequency_student.present?

      daily_frequency_by_student[student_id].add(frequency_date)
    end

    total_school_days = UnitySchoolDay.by_unity_id(unity_id)
                                      .by_year(school_calendar_year)
                                      .by_date_between(start_at, end_at)
                                      .count

    percentage_by_student.each do |student_id, infrequency|
      multiplication = (total_school_days - infrequency) * 100
      result = multiplication / total_school_days
      percentage_by_student[student_id] = result.negative? ? 0.to_s + '%' : result.to_s + '%'
    end

    percentage_by_student
  end

  # def students_frequencies_percentage
  #   percentage_by_student = Hash.new(0)
  #   daily_frequency_by_student = Hash.new { |hash, key| hash[key] = Set.new }

    # fetch_daily_frequencies.flat_map(&:students).each do |daily_frequency_student|
    #   student_id = daily_frequency_student.student_id
    #   frequency_date = daily_frequency_student.daily_frequency.frequency_date

    #   next if daily_frequency_by_student[student_id].include?(frequency_date)

    #   percentage_by_student[student_id] ||= 0
    #   percentage_by_student[student_id] += 1 unless daily_frequency_student.present?

    #   daily_frequency_by_student[student_id].add(frequency_date)
    # end

    # total_school_days = UnitySchoolDay.by_unity_id(unity_id)
    #                                   .by_year(school_calendar_year)
    #                                   .by_date_between(start_at, end_at)
    #                                   .count

    # percentage_by_student.each do |student_id, infrequency|
    #   multiplication = (total_school_days - infrequency) * 100
    #   result = multiplication / total_school_days
    #   percentage_by_student[student_id] = result.negative? ? 0.to_s + '%' : result.to_s + '%'
    # end

    # percentage_by_student
  # end

end
