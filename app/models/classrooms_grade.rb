class ClassroomsGrade < ApplicationRecord
  include Discardable

  belongs_to :classroom
  belongs_to :grade
  belongs_to :exam_rule

  delegate :year, to: :classroom

  has_many :student_enrollment_classrooms
  has_many :student_enrollments, through: :student_enrollment_classrooms
  # Turma de período integral tem um quadro de aulas por turno.
  has_many :lessons_boards

  default_scope -> { kept }

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
  scope :order_by_grade_description, -> { joins(:grade).merge(Grade.ordered) }

  after_discard do
    student_enrollment_classrooms.discard_all
    lessons_boards.discard_all
  end

  # As enturmações também não são alcançadas pela sincronização parcial: o i-Educar filtra as
  # matrículas por `updated_at` próprio, e reativar a turma não toca nesse campo. Sem isso a
  # turma volta sem aluno nenhum até a próxima sincronização completa.
  after_undiscard do
    undiscard_dependents_discarded_with(lessons_boards)
    undiscard_dependents_discarded_with(student_enrollment_classrooms)
  end
end
