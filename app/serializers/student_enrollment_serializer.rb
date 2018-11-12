class StudentEnrollmentSerializer < ActiveModel::Serializer
  attributes :id, :student_id, :status, :active, :sequence

  has_one :student

  def sequence
    object.student_enrollment_classrooms.by_date(Date.current).first.try(:sequence)
  end
end