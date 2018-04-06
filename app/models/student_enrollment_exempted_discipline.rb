class StudentEnrollmentExemptedDiscipline < ActiveRecord::Base
  belongs_to :student_enrollment
  belongs_to :discipline
end
