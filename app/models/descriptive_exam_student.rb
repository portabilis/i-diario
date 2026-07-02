class DescriptiveExamStudent < ApplicationRecord
  include Discardable

  acts_as_copy_target

  audited associated_with: :descriptive_exam, except: [:descriptive_exam_id, :dependence]

  attr_accessor :exempted_from_discipline, :inactive_student

  belongs_to :descriptive_exam
  belongs_to :student

  scope :by_student_id, ->(student_id) { where(student_id: student_id) }
  scope :by_descriptive_exam_id, ->(descriptive_exam_id) { where(descriptive_exam_id: descriptive_exam_id) }
  scope :by_classroom, lambda { |classroom_id|
    joins(:student, :descriptive_exam)
      .includes(:descriptive_exam)
      .merge(
        DescriptiveExam.by_classroom_id(classroom_id)
      )
  }
  scope :by_classroom_and_discipline, lambda { |classroom_id, discipline_id|
    joins(:descriptive_exam).includes(:descriptive_exam).merge(
      DescriptiveExam.by_classroom_id(classroom_id).by_discipline_id(discipline_id)
    )
  }
  scope :ordered, -> { order(:updated_at) }
  scope :by_not_poster, ->(poster_sent) { where("descriptive_exam_students.updated_at > ?", poster_sent) }

  validates :descriptive_exam, :student, presence: true

  before_validation :sanitize_value_content

  private

  # Sanitiza conteúdo HTML permitindo apenas tags básicas (div, p, b, i, u, br)
  def sanitize_value_content
    return if value.blank?

    self.value = ApplicationController.helpers.sanitize(
      value,
      tags: %w[div p b i u br],
      attributes: []
    )
  end
end
