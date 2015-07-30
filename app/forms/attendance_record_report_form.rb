class AttendanceRecordReportForm
  include ActiveModel::Model

  attr_accessor :unity_id,
                :classroom_id,
                :discipline_id,
                :class_numbers,
                :start_at,
                :end_at,
                :school_calendar_year,
                :global_absence

  validates :unity_id,       presence: true
  validates :classroom_id,   presence: true
  validates :discipline_id,  presence: true, unless: :global_absence?
  validates :class_numbers,  presence: true, unless: :global_absence?
  validates :start_at,       presence: true
  validates :end_at,         presence: true
  validates :school_calendar_year, presence: true
  validates :global_absence, presence: true

  validate :start_at_must_be_less_than_or_equal_to_end_at
  validate :start_at_and_end_at_must_be_in_school_calendar_year
  validate :must_have_daily_frequencies

  def daily_frequencies
    if global_absence?
      DailyFrequency.by_unity_classroom_and_frequency_date_between(unity_id, classroom_id, start_at, end_at).order_by_student_name
                                                                                                            .order_by_frequency_date
                                                                                                            .order_by_class_number
    else
      DailyFrequency.by_unity_classroom_discipline_class_number_and_frequency_date_between(unity_id,
                                                                                           classroom_id,
                                                                                           discipline_id,
                                                                                           class_numbers.split(','),
                                                                                           start_at,
                                                                                           end_at).order_by_student_name
                                                                                                  .order_by_frequency_date
                                                                                                  .order_by_class_number
    end
  end

  private

  def global_absence?
    global_absence == "1"
  end

  def start_at_must_be_less_than_or_equal_to_end_at
    return if start_at.empty? || end_at.empty?

    if start_at.to_date > end_at.to_date
      errors.add(:start_at, :start_at_must_be_less_than_or_equal_to_end_at)
    end
  end

  def start_at_and_end_at_must_be_in_school_calendar_year
    return if start_at.empty? || end_at.empty?

    errors.add(:start_at, :start_at_must_be_in_school_calendar_year) if start_at.to_date.year != school_calendar_year.to_i
    errors.add(:end_at, :end_at_must_be_in_school_calendar_year) if end_at.to_date.year != school_calendar_year.to_i
  end

  def must_have_daily_frequencies
    return unless errors.blank?

    if daily_frequencies.count == 0
      errors.add(:daily_frequencies, :must_have_daily_frequencies)
    end
  end
end