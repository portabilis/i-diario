class TeachingPlan < ActiveRecord::Base
  include Audit

  audited except: [:old_contents, :teacher_id]
  has_associated_audits
  acts_as_copy_target

  has_enumeration_for :school_term_type,
                      with: SchoolTermTypes,
                      create_helpers: true
  has_enumeration_for :school_term,
                      with: SchoolTerms

  belongs_to :unity
  belongs_to :grade
  belongs_to :teacher

  validates :year, presence: true
  validates :unity, presence: true
  validates :grade, presence: true
  validates :school_term_type, presence: true
  validates :school_term, presence: { unless: :yearly? }

  has_many :contents_teaching_plans, dependent: :destroy
  has_many :contents, through: :contents_teaching_plans
  has_many :teaching_plan_attachments, dependent: :destroy

  has_one :discipline_teaching_plan, dependent: :restrict_with_error
  has_one :knowledge_area_teaching_plan, dependent: :restrict_with_error

  accepts_nested_attributes_for :contents, allow_destroy: true
  accepts_nested_attributes_for :teaching_plan_attachments, allow_destroy: true

  validate :at_least_one_content_assigned

  scope :by_unity_id, ->(unity_id) { where(unity_id: unity_id) }
  scope :by_teacher_id, ->(teacher_id) { where(teacher_id: teacher_id) }
  scope :by_year, ->(year) { where(year: year) }

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
    contents.order(' "contents_teaching_plans"."id" ')
  end

  def school_term_humanize
    case school_term_type
    when SchoolTermTypes::BIMESTER
      I18n.t("enumerations.bimesters.#{school_term}")
    when SchoolTermTypes::TRIMESTER
      I18n.t("enumerations.trimesters.#{school_term}")
    when SchoolTermTypes::SEMESTER
      I18n.t("enumerations.semesters.#{school_term}")
    when SchoolTermTypes::YEARLY
      I18n.t('enumerations.year.yearly')
    end
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
