class FrequencyInBatchForm < ApplicationRecord
  has_no_table

  attr_accessor :unity_id, :classroom_id, :period, :discipline_id, :start_date, :end_date, :receive_email_confirmation

  validates_date :start_date, :end_date

  validates :unity_id, :classroom_id, :period, presence: true
  validates :frequency_date, presence: true, school_calendar_day: true, posting_date: true

  validate :frequency_date_must_be_less_than_or_equal_to_today


  def frequency_date_must_be_less_than_or_equal_to_today
    return unless start_date || end_date

    if start_date > Time.zone.today
      errors.add(:start_date, :must_be_less_than_or_equal_to_today)
    end
    if end_date > Time.zone.today
      errors.add(:end_date, :must_be_less_than_or_equal_to_today)
    end
  end
end
