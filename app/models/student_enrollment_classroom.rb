class StudentEnrollmentClassroom < ActiveRecord::Base
  belongs_to :classroom
  belongs_to :student_enrollment

  scope :by_classroom, lambda { |classroom_id| where(classroom_id: classroom_id) }
  scope :by_date, lambda { |date| where("(? >= joined_at AND ? < left_at) OR (? >= joined_at AND coalesce(left_at) = '')", date.to_date, date.to_date, date.to_date) }
  scope :by_date_not_before, lambda { |date| where.not('joined_at < ?', date) }
end
