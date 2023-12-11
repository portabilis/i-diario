class AttendanceRecordReportByStudentForm
  include ActiveModel::Model

  attr_accessor :unity_id,
                :classroom_id,
                :period,
                :start_at,
                :end_at,
                :school_calendar_year,
                :school_calendar

  validates :start_at, presence: true, date: true, timeliness: {
    on_or_before: :end_at, type: :date, on_or_before_message: I18n.t('errors.messages.on_or_before_message')
  }
  validates :end_at, presence: true, date: true, timeliness: {
    on_or_after: :start_at, type: :date, on_or_after_message: I18n.t('errors.messages.on_or_after_message')
  }
  validates :unity_id, presence: true
  validates :classroom_id, presence: true
  validates :period, presence: true
  validates :start_at, presence: true
  validates :end_at, presence: true
  validates :school_calendar_year, presence: true
  validates :school_calendar, presence: true

  def fetch_daily_frequencies
    @daily_frequencies ||= DailyFrequencyQuery.call(
      classroom_id: classroom_id,
      period: period,
      frequency_date: start_at..end_at,
      all_students_frequencies: true
    )
  end

  def enrollment_classrooms_list
    adjusted_period = period != Periods::FULL ? period : nil

    enrollment_classrooms_list = StudentEnrollmentClassroomsRetriever.call(
      classrooms: classroom_id,
      disciplines: nil,
      start_at: start_at,
      end_at: end_at,
      search_type: :by_date_range,
      show_inactive: false,
      period: adjusted_period
    )

    @students ||= enrollment_classrooms_list.map { |student_enrollment|
      student_enrollment[:student]
    }
  end

  def students_frequencies_percentage
    percentage_by_student = {}
    fetch_daily_frequencies
  end

end
