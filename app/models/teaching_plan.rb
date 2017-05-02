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

  validates :year, presence: true
  validates :unity, presence: true
  validates :grade, presence: true
  validates :school_term_type, presence: true
  validates :school_term, presence: { unless: :yearly? }

  has_many :contents_teaching_plans, dependent: :destroy
  has_many :contents, through: :contents_teaching_plans

  has_one :discipline_teaching_plan
  has_one :knowledge_area_teaching_plan

  accepts_nested_attributes_for :contents, allow_destroy: true

  validate :at_least_one_content_assigned

  def contents_tags
    if @contents_tags.present?
      ContentTagConverter::tags_to_json(@contents_tags)
    else
      ContentTagConverter::contents_to_json(contents_ordered)
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
    end
  end

  private

  def at_least_one_content_assigned
    errors.add(:contents, :at_least_one_content_assigned) if contents.empty?
  end
end
