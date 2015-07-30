class AttendanceRecordReportForm
  include ActiveModel::Model

  attr_accessor :unity_id,
                :classroom_id,
                :discipline_id,
                :class_numbers,
                :start_at,
                :end_at,
                :global_absence

  validates :unity_id,       presence: true
  validates :classroom_id,   presence: true
  validates :discipline_id,  presence: true, unless: :global_absence?
  validates :class_numbers,  presence: true
  validates :start_at,       presence: true
  validates :end_at,         presence: true
  validates :global_absence, presence: true

  validate :start_at_must_be_less_than_or_equal_to_end_at
  validate :must_have_daily_frequencies

  def daily_frequencies
    DailyFrequency.where(unity_id: unity_id,
                         classroom_id: classroom_id,
                         discipline_id: discipline_id,
                         class_number: class_numbers.split(','),
                         frequency_date: start_at.to_date..end_at.to_date)
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

  def must_have_daily_frequencies
    if daily_frequencies.count == 0
      errors.add(:daily_frequencies, :teste)
    end
  end
end