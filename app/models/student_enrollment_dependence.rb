class StudentEnrollmentDependence < ActiveRecord::Base
  belongs_to :student_enrollment
  belongs_to :discipline

  scope :by_student_enrollment, lambda { |student_enrollment_id| where(student_enrollment_id: student_enrollment_id) }
  scope :by_discipline, lambda { |discipline_id| where(discipline_id: discipline_id) }
end
