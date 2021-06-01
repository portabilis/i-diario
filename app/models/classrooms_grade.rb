class ClassroomsGrade < ActiveRecord::Base
  belongs_to :classroom
  belongs_to :grade
  belongs_to :exam_rule
  has_and_belongs_to_many :avaliations
  has_many :student_enrollment_classrooms
  has_many :student_enrollments, through: :student_enrollment_classrooms

  scope :by_classroom_id, ->(classroom_id) { where(classroom_id: classroom_id) }
  scope :by_score_type, ->(score_type) { joins(:exam_rule).where(exam_rules: { score_type: score_type }) }
  scope :by_student_id, lambda { |student_id|
    joins(:student_enrollments).where(student_enrollments: { student_id: student_id })
  }
end
