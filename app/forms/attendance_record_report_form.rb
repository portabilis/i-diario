class AttendanceRecordReportForm
  include ActiveModel::Model

  attr_accessor :unity_id,
                :classroom_id,
                :period,
                :discipline_id,
                :class_numbers,
                :start_at,
                :end_at,
                :school_calendar_year,
                :current_teacher_id,
                :school_calendar,
                :second_teacher_signature,
                :display_knowledge_area_as_discipline

  validates :start_at, presence: true, date: true, timeliness: {
    on_or_before: :end_at, type: :date, on_or_before_message: I18n.t('errors.messages.on_or_before_message')
  }
  validates :end_at, presence: true, date: true, timeliness: {
    on_or_after: :start_at, type: :date, on_or_after_message: I18n.t('errors.messages.on_or_after_message')
  }
  validates :unity_id, presence: true
  validates :classroom_id, presence: true
  validates :period, presence: true
  validates :discipline_id, presence: true, unless: :global_absence?
  validates :class_numbers, presence: true, unless: :global_absence?
  validates :start_at, presence: true
  validates :end_at, presence: true
  validates :school_calendar_year, presence: true
  validates :school_calendar, presence: true
  validate :must_have_daily_frequencies

  def daily_frequencies
    if global_absence?
      DailyFrequency.by_classroom_id(classroom_id)
                    .by_period(period)
                    .by_frequency_date_between(start_at, end_at)
                    .general_frequency
                    .includes(students: :student)
                    .order_by_frequency_date
                    .order_by_class_number
                    .order_by_student_name

    else
      DailyFrequency.by_classroom_id(classroom_id)
                    .by_period(period)
                    .by_discipline_id(discipline_id)
                    .by_class_number(class_numbers.split(','))
                    .by_frequency_date_between(start_at, end_at)
                    .includes(students: :student)
                    .order_by_frequency_date
                    .order_by_class_number
                    .order_by_student_name
    end
  end

  def school_calendar_events
    events_by_day = []
    events = school_calendar.events
                            .without_frequency
                            .by_date_between(start_at, end_at)
                            .all_events_for_classroom(classroom)
                            .where(
                              SchoolCalendarEvent.arel_table[:discipline_id].eq(nil).or(
                                SchoolCalendarEvent.arel_table[:discipline_id].eq(discipline_id)
                              )
                            )
                            .ordered

    events.each do |event|
      (event.start_date..event.end_date).each do |date|
        events_by_day << {
          date: date,
          legend: event.legend,
          description: event.description
        }
      end
    end
    events_by_day
  end

  def students_enrollments
    adjusted_period = period != Periods::FULL ? period : nil

    StudentEnrollmentsList.new(
      classroom: classroom_id,
      discipline: discipline_id,
      start_at: start_at,
      end_at: end_at,
      search_type: :by_date_range,
      show_inactive: false,
      period: adjusted_period
    ).student_enrollments
  end

  private

  def remove_duplicated_enrollments(students_enrollments)
    students_enrollments = students_enrollments.select do |student_enrollment|
      enrollments_for_student = StudentEnrollment.by_student(student_enrollment.student_id)
                                                 .by_classroom(classroom_id)

      if enrollments_for_student.count > 1
        enrollments_for_student.last != student_enrollment
      else
        true
      end
    end

    students_enrollments
  end

  def global_absence?
    frequency_type_definer = FrequencyTypeDefiner.new(classroom, teacher, year: classroom.year)
    frequency_type_definer.define!
    frequency_type_definer.frequency_type == FrequencyTypes::GENERAL
  end

  def must_have_daily_frequencies
    return if errors.present?

    errors.add(:daily_frequencies, :must_have_daily_frequencies) if daily_frequencies.count.zero?
  end

  def classroom
    Classroom.find(@classroom_id)
  end

  def teacher
    Teacher.find(@current_teacher_id)
  end
end
