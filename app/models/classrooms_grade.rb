class ClassroomsGrade < ActiveRecord::Base
  belongs_to :classroom
  belongs_to :grade
  belongs_to :exam_rule
  has_and_belongs_to_many :avaliations
  has_many :student_enrollment_classrooms
  has_many :student_enrollments, through: :student_enrollment_classrooms
end
