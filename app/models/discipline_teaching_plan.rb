class DisciplineTeachingPlan < ActiveRecord::Base
  include Audit

  acts_as_copy_target

  audited
  has_associated_audits

  belongs_to :teaching_plan, dependent: :destroy
  belongs_to :discipline

  accepts_nested_attributes_for :teaching_plan

  scope :by_year, lambda { |year| joins(:teaching_plan).where(teaching_plans: { year: year }) }
  scope :by_unity, lambda { |unity| joins(:teaching_plan).where(teaching_plans: { unity_id: unity }) }
  scope :by_grade, lambda { |grade| joins(:teaching_plan).where(teaching_plans: { grade_id: grade }) }
  scope :by_school_term, lambda { |school_term| joins(:teaching_plan).where(teaching_plans: { school_term: school_term }) }
  scope :by_discipline, lambda { |discipline| where(discipline: discipline) }

  validates :teaching_plan, presence: true
  validates :discipline, presence: true

  validate :uniqueness_of_discipline_teaching_plan, if: :teaching_plan

  private

  def uniqueness_of_discipline_teaching_plan
    discipline_teaching_plans = DisciplineTeachingPlan.by_year(teaching_plan.year)
      .by_unity(teaching_plan.unity)
      .by_grade(teaching_plan.grade)
      .by_school_term(teaching_plan.school_term)
      .by_discipline(discipline)

    if persisted?
      discipline_teaching_plans = discipline_teaching_plans.where.not(id: id)
    end

    if discipline_teaching_plans.any?
      errors.add(:discipline, :taken)
    end
  end
end
