class ClassroomsGrade < ActiveRecord::Base
  belongs_to :classroom
  belongs_to :grade
  belongs_to :exam_rule
  has_and_belongs_to_many :avaliations
  has_many :student_enrollment_classrooms
  has_many :student_enrollments, through: :student_enrollment_classrooms

  scope :by_score_type, ->(score_type) { joins(:exam_rule).where(exam_rules: { score_type: score_type }) }
end
