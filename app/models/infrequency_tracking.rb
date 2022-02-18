class InfrequencyTracking < ActiveRecord::Base
  audited

  belongs_to :classroom
  belongs_to :student
  belongs_to :mvw_infrequency_tracking_student, foreign_key: :student_id, inverse_of: :infrequency_trackings
  belongs_to :mvw_infrequency_tracking_classroom, foreign_key: :classroom_id, inverse_of: :infrequency_trackings

  has_enumeration_for :notification_type, with: InfrequencyTrackingTypes

  validates :classroom_id, :student_id, :notification_date, :notification_data,
            :notification_type, presence: true

  scope :by_classroom_id, ->(classroom_id) { where(classroom_id: classroom_id) }
  scope :by_student_id, ->(student_id) { where(student_id: student_id) }
  scope :by_unity_id, ->(unity_id) { joins(:classroom).where(classrooms: { unity_id: unity_id }) }
  scope :by_grade_id, ->(grade_id) { joins(:classroom).merge(Classroom.by_grade(grade_id)) }
  scope :by_notification_date, ->(notification_date) { where(notification_date: notification_date.to_date) }
  scope :by_notification_type, ->(notification_type) { where(notification_type: notification_type) }
  scope :ordered, -> { order(notification_date: :desc) }
end
