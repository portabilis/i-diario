class DailyPhysicalFrequency < ApplicationRecord
  belongs_to :student_enrollment
  belongs_to :unity

  validates :frequency_date, presence: true
  validates :student_enrollment_id, presence: true
  validates :present, inclusion: { in: [true, false] }

  validates :frequency_date, uniqueness: { scope: :student_enrollment_id, message: "já possui frequência registrada para este aluno neste dia" }
end

