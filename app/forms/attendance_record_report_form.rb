class AttendanceRecordReportForm
  include ActiveModel::Model

  attr_accessor :unity_id,
                :classroom_id,
                :discipline_id,
                :class_numbers,
                :start_at,
                :end_at,
                :school_calendar_year,
                :current_teacher_id,
                :school_calendar

  validates :unity_id,       presence: true
  validates :classroom_id,   presence: true
  validates :discipline_id,  presence: true, unless: :global_absence?
  validates :class_numbers,  presence: true, unless: :global_absence?
  validates :start_at,       presence: true
  validates :end_at,         presence: true
  validates :school_calendar_year, presence: true
  validates :school_calendar, presence: true

  validate :start_at_must_be_a_valid_date
  validate :end_at_must_be_a_valid_date
  validate :start_at_must_be_less_than_or_equal_to_end_at
  validate :start_at_must_be_in_school_calendar_year
  validate :end_at_must_be_in_school_calendar_year
  validate :must_have_daily_frequencies

  def daily_frequencies
    if global_absence?
      DailyFrequency
        .by_classroom_id(classroom_id)
        .by_frequency_date_between(start_at, end_at)
        .general_frequency
        .includes(students: :student)
        .order_by_frequency_date
        .order_by_class_number
        .order_by_student_name

    else
      DailyFrequency
        .by_classroom_id(classroom_id)
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
    school_calendar.events
                   .without_frequency
                   .by_date_between(start_at, end_at)
                   .all_events_for_classroom(classroom)
                   .where(SchoolCalendarEvent.arel_table[:discipline_id].eq(nil).or(SchoolCalendarEvent.arel_table[:discipline_id].eq(discipline_id)))
                   .ordered
  end

  def students_enrollments
    StudentEnrollmentsList.new(classroom: classroom_id,
                               discipline: discipline_id,
                               start_at: start_at,
                               end_at: end_at,
                               search_type: :by_date_range).student_enrollments
  end

  private

  def remove_duplicated_enrollments(students_enrollments)
    students_enrollments = students_enrollments.select do |student_enrollment|
      enrollments_for_student = StudentEnrollment
        .by_student(student_enrollment.student_id)
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
    frequency_type_definer = FrequencyTypeDefiner.new(classroom, teacher)
    frequency_type_definer.define!
    frequency_type_definer.frequency_type == FrequencyTypes::GENERAL
  end

  def start_at_must_be_a_valid_date
    return if errors[:start_at].any?

    begin
      start_at.to_date
    rescue ArgumentError
      errors.add(:start_at, :must_be_a_valid_date)
    end
  end

  def end_at_must_be_a_valid_date
    return if errors[:end_at].any?

    begin
      end_at.to_date
    rescue ArgumentError
      errors.add(:end_at, :must_be_a_valid_date)
    end
  end

  def start_at_must_be_less_than_or_equal_to_end_at
    return if errors[:start_at].any? || errors[:end_at].any?

    if start_at.to_date > end_at.to_date
      errors.add(:start_at, :start_at_must_be_less_than_or_equal_to_end_at)
    end
  end

  def start_at_must_be_in_school_calendar_year
    return if errors[:start_at].any?

    errors.add(:start_at, :must_be_in_school_calendar_year) if start_at.to_date.year != school_calendar_year.to_i
  end

  def end_at_must_be_in_school_calendar_year
    return if errors[:end_at].any?

    errors.add(:end_at, :must_be_in_school_calendar_year) if end_at.to_date.year != school_calendar_year.to_i
  end

  def must_have_daily_frequencies
    return unless errors.blank?

    if daily_frequencies.count == 0
      errors.add(:daily_frequencies, :must_have_daily_frequencies)
    end
  end

  def classroom
    Classroom.find(@classroom_id)
  end

  def teacher
    Teacher.find(@current_teacher_id)
  end
end
