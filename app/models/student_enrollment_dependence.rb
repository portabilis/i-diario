class StudentEnrollmentDependence < ApplicationRecord
  include Discardable

  audited

  belongs_to :student_enrollment
  belongs_to :discipline

  default_scope -> { kept }

  scope :by_student_enrollment, lambda { |student_enrollment_id| where(student_enrollment_id: student_enrollment_id) }
  scope :by_discipline, lambda { |discipline_id| where(discipline_id: discipline_id) }

  def self.discipline_ids_for(student_id, classroom_id)
    enrollment_ids = StudentEnrollment.by_student(student_id)
                                      .by_classroom(classroom_id)
                                      .pluck(:id)
    return [] if enrollment_ids.blank?

    by_student_enrollment(enrollment_ids).pluck(:discipline_id)
  end
end
