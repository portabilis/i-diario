class DailyPhysicalFrequency < ApplicationRecord
  belongs_to :student_enrollment
  belongs_to :unity

  validates :frequency_date, presence: true
  validates :student_enrollment_id, presence: true
  validates :present, inclusion: { in: [true, false] }
end

