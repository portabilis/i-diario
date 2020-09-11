class KnowledgeArea < ActiveRecord::Base
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
    ).uniq
  }
  scope :by_teacher, lambda { |teacher_id|
    joins(disciplines: :teacher_discipline_classrooms).where(
      teacher_discipline_classrooms: { teacher_id: teacher_id }
    ).uniq
  }
  scope :by_classroom_id, lambda { |classroom_id|
    joins(disciplines: :teacher_discipline_classrooms).where(
      teacher_discipline_classrooms: { classroom_id: classroom_id }
    ).uniq
  }
  scope :by_grade, lambda { |grade_id|
    joins(disciplines: { teacher_discipline_classrooms: :classroom }).where(
      classrooms: { grade_id: grade_id }
    ).uniq
  }
  scope :by_discipline_id, ->(discipline_id) { joins(:disciplines).where(disciplines: { id: discipline_id }) }
  scope :ordered, -> { order(arel_table[:description].asc) }

  def to_s
    description
  end

  def self.with_discipline(entity, classroom_id, teacher_id)
    cache_key = ['KnowledgeArea.with_discipline', entity.id, classroom_id, teacher_id, 'v2']

    Rails.cache.fetch cache_key, expires_in: 10.minutes do
      Discipline
        .joins(:knowledge_area)
        .by_teacher_id(teacher_id)
        .by_classroom(classroom_id)
        .select(
          <<-SQL
                CASE
                    WHEN knowledge_areas.group_descriptors THEN knowledge_areas.description
                    ELSE disciplines.description
                END AS description,
                CASE
                    WHEN knowledge_areas.group_descriptors THEN knowledge_area_id
                END AS knowledge_area_id,
                CASE
                    WHEN NOT knowledge_areas.group_descriptors THEN disciplines.id
                END AS discipline_id
          SQL
        )
    end
  end
end
