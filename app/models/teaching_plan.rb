class TeachingPlan < ActiveRecord::Base
  include Audit

  acts_as_copy_target

  audited

  has_enumeration_for :school_term_type,
    with: SchoolTermTypes,
    create_helpers: true

  belongs_to :unity
  belongs_to :grade

  validates :year, presence: true
  validates :unity, presence: true
  validates :grade, presence: true
  validates :school_term_type, presence: true
  validates :school_term, presence: { unless: :yearly?  }

  has_and_belongs_to_many :contents, dependent: :destroy
  accepts_nested_attributes_for :contents, reject_if: :all_blank, allow_destroy: true

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
