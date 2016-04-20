class AttendanceRecordReportForm
  include ActiveModel::Model

  attr_accessor :unity_id,
                :classroom_id,
                :discipline_id,
                :class_numbers,
                :start_at,
                :end_at,
                :school_calendar_year,
                :current_teacher_id

  validates :unity_id,       presence: true
  validates :classroom_id,   presence: true
  validates :discipline_id,  presence: true, unless: :global_absence?
  validates :class_numbers,  presence: true, unless: :global_absence?
  validates :start_at,       presence: true
  validates :end_at,         presence: true
  validates :school_calendar_year, presence: true

  validate :start_at_must_be_a_valid_date
  validate :end_at_must_be_a_valid_date
  validate :start_at_must_be_less_than_or_equal_to_end_at
  validate :start_at_must_be_in_school_calendar_year
  validate :end_at_must_be_in_school_calendar_year
  validate :must_have_daily_frequencies

  def daily_frequencies
    if global_absence?
      DailyFrequency.by_unity_classroom_and_frequency_date_between(
        unity_id,
        classroom_id,
        start_at,
        end_at
      )
      .order_by_frequency_date
      .order_by_class_number
      .order_by_student_name

    else
      DailyFrequency.by_unity_classroom_discipline_class_number_and_frequency_date_between(
        unity_id,
        classroom_id,
        discipline_id,
        class_numbers.split(','),
        start_at,
        end_at
      )
      .order_by_frequency_date
      .order_by_class_number
      .order_by_student_name
    end
  end

  def students
    students_ids = []
    daily_frequencies.each { |d| students_ids << d.students.map(&:student_id) }
    students_ids.flatten!.uniq!

    Student.find(students_ids)
  end

  private

  def global_absence?
    frequency_type_definer = FrequencyTypeDefiner.new(classroom, current_teacher)
    frequency_type_definer.frequency_type == FrequencyTypes::GENERAL
  end

  def classroom
    Classroom.find(classroom_id)
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

  def current_teacher
    Teacher.find(current_teacher_id)
  end
end
