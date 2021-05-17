class ClassroomGrade < ActiveRecord::Base
  belongs_to :classroom
  belongs_to :grade
  belongs_to :exam_rule
  has_many :student_enrollment_classrooms
  has_many :student_enrollments, through: :student_enrollment_classrooms
end
