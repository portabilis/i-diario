class DailyPhysicalFrequency < ApplicationRecord
  belongs_to :student_enrollment
  belongs_to :unity

  validates :frequency_date, presence: true
  validates :student_enrollment_id, presence: true
  validates :present, inclusion: { in: [true, false] }

  scope :by_unity_api_code, ->(api_code) {
    return all if api_code.blank?
    joins(:unity).where(unities: { api_code: api_code })
  }

  scope :by_student_enrollment_api_code, ->(api_code) {
    return all if api_code.blank?
    joins(:student_enrollment).where(student_enrollments: { api_code: api_code })
  }

  scope :by_frequency_date, ->(date) {
    return all if date.blank?
    where(frequency_date: date)
  }
end

