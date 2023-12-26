class UniqueDailyFrequencyStudent < ApplicationRecord
  audited

  belongs_to :student
  belongs_to :classroom

  validates :classroom_id, :student_id, :frequency_date, presence: true

  scope :by_classroom_id, ->(classroom_id) { where(classroom_id: classroom_id) }
  scope :by_student_id, ->(student_id) { where(student_id: student_id) }
  scope :by_unity_id, ->(unity_id) { joins(:classroom).where(classrooms: { unity_id: unity_id }) }
  scope :by_grade_id, ->(grade_id) { joins(:classroom).merge(Classroom.by_grade(grade_id)) }
  scope :frequency_date, ->(frequency_date) { where(frequency_date: frequency_date) }
  scope :frequency_date_between, ->(start_at, end_at) { where(frequency_date: start_at.to_date..end_at.to_date) }
  scope :by_teacher_id, lambda { |teacher_id|
    where("'{?}' && unique_daily_frequency_students.absences_by", teacher_id.to_i)
  }
  scope :ordered, -> { order(frequency_date: :desc) }
end
