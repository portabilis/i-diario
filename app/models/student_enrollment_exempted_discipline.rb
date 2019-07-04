class StudentEnrollmentExemptedDiscipline < ActiveRecord::Base
  include Discardable

  audited

  belongs_to :student_enrollment
  belongs_to :discipline

  default_scope -> { kept }

  scope :by_discipline, lambda { |discipline_id| where(discipline_id: discipline_id) }
  scope :by_student_enrollment, lambda { |student_enrollment_id| where(student_enrollment_id: student_enrollment_id) }
  scope :by_step_number, lambda { |step_number| where("? = ANY(string_to_array(steps, ',')::integer[])", step_number) }
end
