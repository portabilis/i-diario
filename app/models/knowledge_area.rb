class KnowledgeArea < ApplicationRecord
  include Discardable

  acts_as_copy_target

  audited

  include Audit

  has_many :disciplines, dependent: :destroy
  has_and_belongs_to_many :knowledge_area_content_records

  validates :description, :api_code, presence: true
  validates :api_code, uniqueness: true

  default_scope -> { kept }

  scope :by_unity, lambda { |unity_id|
    joins(disciplines: { teacher_discipline_classrooms: :classroom }).where(
      classrooms: { unity_id: unity_id }
    ).distinct
  }
  scope :by_teacher, lambda { |teacher_id|
    joins(disciplines: :teacher_discipline_classrooms).where(
      teacher_discipline_classrooms: { teacher_id: teacher_id }
    ).distinct
  }
  scope :by_classroom_id, lambda { |classroom_id|
    joins(disciplines: :teacher_discipline_classrooms).where(
      teacher_discipline_classrooms: { classroom_id: classroom_id }
    ).distinct
  }
  scope :by_grade, lambda { |grade_id|
    joins(disciplines: { teacher_discipline_classrooms: { classroom: :classrooms_grades } }).where(
      classrooms_grades: { grade_id: grade_id }
    ).distinct
  }
  scope :by_discipline_id, ->(discipline_id) { joins(:disciplines).where(disciplines: { id: discipline_id }) }
  scope :ordered, -> { order(arel_table[:description].asc) }

  def to_s
    description
  end
end
