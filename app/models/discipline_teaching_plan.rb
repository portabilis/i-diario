class DisciplineTeachingPlan < ActiveRecord::Base
  include Audit

  audited
  has_associated_audits

  acts_as_copy_target

  belongs_to :teaching_plan, dependent: :destroy
  belongs_to :discipline

  delegate :contents, to: :teaching_plan

  accepts_nested_attributes_for :teaching_plan

  scope :by_year, ->(year) { joins(:teaching_plan).where(teaching_plans: { year: year }) }
  scope :by_unity, ->(unity) { joins(:teaching_plan).where(teaching_plans: { unity_id: unity }) }
  scope :by_grade, ->(grade) { joins(:teaching_plan).where(teaching_plans: { grade_id: grade }) }
  scope :by_school_term_type, lambda { |school_term_type|
    joins(:teaching_plan).where(teaching_plans: { school_term_type: school_term_type })
  }
  scope :by_school_term, lambda { |school_term|
    joins(:teaching_plan).where(teaching_plans: { school_term: school_term })
  }
  scope :by_discipline, ->(discipline) { where(discipline: discipline) }
  scope :by_teacher_id, ->(teacher_id) { joins(:teaching_plan).where(teaching_plans: { teacher_id: teacher_id }) }
  scope :by_other_teacher_id, lambda { |teacher_id|
    joins(:teaching_plan).where.not(teaching_plans: { teacher_id: [teacher_id, nil] })
  }
  scope :by_secretary, -> { joins(:teaching_plan).where(teaching_plans: { teacher_id: nil }) }
  scope :by_author, lambda { |author_type, current_teacher_id|
    if author_type == PlansAuthors::MY_PLANS
      joins(:teaching_plan).merge(TeachingPlan.where(teacher_id: current_teacher_id))
    else
      joins(:teaching_plan).merge(TeachingPlan.where.not(teacher_id: current_teacher_id))
    end
  }

  validates :teaching_plan, presence: true
  validates :discipline, presence: true

  validate :uniqueness_of_discipline_teaching_plan, if: :teaching_plan

  private

  def uniqueness_of_discipline_teaching_plan
    discipline_teaching_plans = DisciplineTeachingPlan.by_year(teaching_plan.year)
                                                      .by_unity(teaching_plan.unity)
                                                      .by_teacher_id(teaching_plan.teacher_id)
                                                      .by_grade(teaching_plan.grade)
                                                      .by_school_term(teaching_plan.school_term)
                                                      .by_discipline(discipline)

    discipline_teaching_plans = discipline_teaching_plans.where.not(id: id) if persisted?

    errors.add(:base, :uniqueness_of_discipline_teaching_plan) if discipline_teaching_plans.any?
  end
end
