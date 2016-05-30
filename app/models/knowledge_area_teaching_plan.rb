class KnowledgeAreaTeachingPlan < ActiveRecord::Base
  include Audit

  acts_as_copy_target

  audited
  has_associated_audits

  belongs_to :teaching_plan, dependent: :destroy
  has_many :knowledge_area_teaching_plan_knowledge_areas, dependent: :destroy
  has_many :knowledge_areas, through: :knowledge_area_teaching_plan_knowledge_areas

  delegate :contents, to: :teaching_plan

  accepts_nested_attributes_for :teaching_plan

  scope :by_year, lambda { |year| joins(:teaching_plan).where(teaching_plans: { year: year }) }
  scope :by_unity, lambda { |unity| joins(:teaching_plan).where(teaching_plans: { unity_id: unity }) }
  scope :by_grade, lambda { |grade| joins(:teaching_plan).where(teaching_plans: { grade_id: grade }) }
  scope :by_school_term_type, lambda { |school_term_type| joins(:teaching_plan).where(teaching_plans: { school_term_type: school_term_type }) }
  scope :by_school_term, lambda { |school_term| joins(:teaching_plan).where(teaching_plans: { school_term: school_term }) }
  scope :by_knowledge_area, lambda { |knowledge_area| by_knowledge_area(knowledge_area) }
  scope :by_teacher_id, lambda { |teacher_id| joins(:teaching_plan).where(teaching_plans: { teacher_id: teacher_id})  }

  validates :teaching_plan, presence: true
  validates :knowledge_area_ids, presence: true

  validate :uniqueness_of_knowledge_area_teaching_plan, if: :teaching_plan

  def knowledge_area_ids
    knowledge_areas.collect(&:id).join(',')
  end

  private

  def self.by_knowledge_area(knowledge_area)
    joins(:knowledge_area_teaching_plan_knowledge_areas)
      .where(
        knowledge_area_teaching_plan_knowledge_areas: {
          knowledge_area_id: knowledge_area
        }
      )
  end

  def uniqueness_of_knowledge_area_teaching_plan
    knowledge_area_teaching_plans = KnowledgeAreaTeachingPlan.by_year(teaching_plan.year)
      .by_unity(teaching_plan.unity)
      .by_grade(teaching_plan.grade)
      .by_school_term(teaching_plan.school_term)
      .by_knowledge_area(knowledge_areas.collect(&:id))

    knowledge_area_teaching_plans = knowledge_area_teaching_plans.where.not(id: id) if persisted?

    if knowledge_area_teaching_plans.any?
      errors.add(:knowledge_area_ids, :taken)
    end
  end
end
