class TeachingPlan < ApplicationRecord
  include Audit
  include TeacherRelationable
  include Translatable

  teacher_relation_columns only: :grades

  audited except: [:old_contents]
  has_associated_audits
  acts_as_copy_target

  belongs_to :unity
  belongs_to :grade
  belongs_to :teacher
  belongs_to :school_term_type
  belongs_to :school_term_type_step

  validates :year, presence: true
  validates :unity, presence: true
  validates :grade, presence: true
  validates :school_term_type, presence: true
  validates :school_term_type_step, presence: { unless: :yearly? }

  has_many :contents_teaching_plans, dependent: :destroy
  deferred_has_many :contents, through: :contents_teaching_plans, dependent: :destroy
  has_many :objectives_teaching_plans, dependent: :destroy
  deferred_has_many :objectives, through: :objectives_teaching_plans, dependent: :destroy
  has_many :teaching_plan_attachments, dependent: :destroy

  has_one :discipline_teaching_plan, dependent: :restrict_with_error
  has_one :knowledge_area_teaching_plan, dependent: :restrict_with_error

  accepts_nested_attributes_for :contents, allow_destroy: true
  accepts_nested_attributes_for :objectives, allow_destroy: true
  accepts_nested_attributes_for :teaching_plan_attachments, allow_destroy: true

  validate :at_least_one_content_assigned

  scope :by_unity_id, ->(unity_id) { where(unity_id: unity_id) }
  scope :by_teacher_id, ->(teacher_id) { where(teacher_id: teacher_id) }
  scope :by_year, ->(year) { where(year: year) }

  attr_accessor :grade_ids, :contents_created_at_position, :objectives_created_at_position

  def to_s
    return discipline_teaching_plan.discipline.to_s if discipline_teaching_plan
    return knowledge_area_teaching_plan.knowledge_areas.ordered.first.to_s if knowledge_area_teaching_plan
  end

  def contents_tags
    if @contents_tags.present?
      ContentTagConverter.tags_to_json(@contents_tags)
    else
      ContentTagConverter.contents_to_json(contents_ordered)
    end
  end

  def contents_ordered
    contents.order('contents_teaching_plans.position')
  end

  def objectives_ordered
    objectives.order('objectives_teaching_plans.position')
  end

  def school_term_type_step_humanize
    return '' if yearly?

    school_term_type_step.to_s
  end

  def optional_teacher
    true
  end

  def attachments?
    teaching_plan_attachments.any?
  end

  def yearly?
    return unless school_term_type

    SchoolTermType.where("description ILIKE 'Anual%'").where(id: school_term_type.id).exists?
  end

  private

  def at_least_one_content_assigned
    return unless contents_empty?

    errors.add(:contents, :at_least_one_content_assigned)
  end

  def contents_empty?
    contents.empty? || (contents.size == contents.select(&:marked_for_destruction?).size)
  end
end
