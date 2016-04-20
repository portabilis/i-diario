class DailyFrequencyStudent < ActiveRecord::Base
  acts_as_copy_target

  audited associated_with: :daily_frequency, except: :daily_frequency_id

  belongs_to :daily_frequency
  belongs_to :student

  delegate :frequency_date, to: :daily_frequency

  validates :student, :daily_frequency, presence: true

  scope :absences, -> { where("COALESCE(daily_frequency_students.present, 'f') = 'f' ")}
  scope :general_by_classroom_student_date_between,
        lambda { |classroom_id, student_id, start_at, end_at| where(
                                                       'daily_frequencies.classroom_id' => classroom_id,
                                                       student_id: student_id,
                                                       'daily_frequencies.frequency_date' => start_at.to_date..end_at.to_date,
                                                       'daily_frequencies.discipline_id' => nil)
                                                          .includes(:daily_frequency) }
  scope :general_by_classroom_discipline_student_date_between,
        lambda { |classroom_id, discipline_id, student_id, start_at, end_at| where(
                                                       'daily_frequencies.classroom_id' => classroom_id,
                                                       'daily_frequencies.discipline_id' => discipline_id,
                                                       student_id: student_id,
                                                       'daily_frequencies.frequency_date' => start_at.to_date..end_at.to_date)
                                                          .includes(:daily_frequency) }

  def to_s
    present ? '.' : 'F'
  end
end
