class ComplementaryExamStudent < ApplicationRecord
  include Audit
  include Discardable

  audited associated_with: :complementary_exam, except: [:complementary_exam_id]

  acts_as_copy_target

  attr_accessor :dependence, :active, :exempted_from_discipline

  belongs_to :complementary_exam
  belongs_to :student

  default_scope -> { kept }

  scope :by_student_id, lambda { |student_id| where(student_id: student_id) }
  scope :by_complementary_exam_id, lambda { |complementary_exam_id| where(complementary_exam_id: complementary_exam_id) }

  scope :ordered, -> { joins(:student).order(Student.arel_table[:name]) }

  delegate :to_s, to: :student

  validates :complementary_exam, presence: true
  validates(
    :score,
    numericality: {
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: lambda { |r| r.maximum_score }
    },
    allow_blank: true
  )

  def maximum_score
    @maximum_score ||= complementary_exam.maximum_score
  end
end
