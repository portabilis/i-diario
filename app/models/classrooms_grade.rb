class ClassroomsGrade < ActiveRecord::Base
  belongs_to :classroom
  belongs_to :grade
  belongs_to :exam_rule

  delegate :year, to: :classroom

  has_many :student_enrollment_classrooms
  has_many :student_enrollments, through: :student_enrollment_classrooms

  scope :by_classroom_id, ->(classroom_id) { where(classroom_id: classroom_id) }
  scope :by_score_type, ->(score_type) { joins(:exam_rule).where(exam_rules: { score_type: score_type }) }
  scope :by_grade_id, ->(grade_id) { where(grade_id: grade_id) }
  scope :by_opinion_type, ->(opinion_type) { joins(:exam_rule).where(exam_rules: { opinion_type: opinion_type }) }
  scope :by_exam_rule, ->(exam_rule_id) { joins(:exam_rule).where(exam_rules: { id: exam_rule_id }) }
  scope :by_id, ->(id) { joins(:exam_rule).where(id: id) }
  scope :by_year, ->(year) { joins(:classroom).where(classrooms: { year: year }) }
  scope :by_student_id, lambda { |student_id|
    joins(:student_enrollments).where(student_enrollments: { student_id: student_id })
  }
end
