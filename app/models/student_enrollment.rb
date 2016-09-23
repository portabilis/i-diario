class StudentEnrollment < ActiveRecord::Base
  belongs_to :student

  has_many :student_enrollment_classrooms
end
