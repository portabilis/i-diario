class DisciplineTeachingPlan < ActiveRecord::Base
  include Audit

  acts_as_copy_target

  audited
  has_associated_audits

  belongs_to :teaching_plan, dependent: :destroy
  belongs_to :discipline

  delegate :contents, to: :teaching_plan

  accepts_nested_attributes_for :teaching_plan

  scope :by_year, lambda { |year| joins(:teaching_plan).where(teaching_plans: { year: year }) }
  scope :by_unity, lambda { |unity| joins(:teaching_plan).where(teaching_plans: { unity_id: unity }) }
  scope :by_grade, lambda { |grade| joins(:teaching_plan).where(teaching_plans: { grade_id: grade }) }
  scope :by_school_term_type, lambda { |school_term_type| joins(:teaching_plan).where(teaching_plans: { school_term_type: school_term_type }) }
  scope :by_school_term, lambda { |school_term| joins(:teaching_plan).where(teaching_plans: { school_term: school_term }) }
  scope :by_discipline, lambda { |discipline| where(discipline: discipline) }
  scope :by_teacher, lambda { |teacher| by_teacher(teacher) }

  validates :teaching_plan, presence: true
  validates :discipline, presence: true

  validate :uniqueness_of_discipline_teaching_plan, if: :teaching_plan

  private

  def self.by_teacher(teacher)
    joins(:teaching_plan).joins(
      arel_table.join(TeacherDisciplineClassroom.arel_table, Arel::Nodes::OuterJoin)
        .on(
          TeacherDisciplineClassroom.arel_table[:discipline_id]
            .eq(arel_table[:discipline_id])
            .and(TeachingPlan.arel_table[:year]
                  .eq(TeacherDisciplineClassroom.arel_table[:year]))
          ).join_sources
      )
      .joins(
        arel_table.join(Classroom.arel_table, Arel::Nodes::OuterJoin)
          .on(
            Classroom.arel_table[:grade_id]
              .eq(TeachingPlan.arel_table[:grade_id])
              .and(
                Classroom.arel_table[:id]
                  .eq(TeacherDisciplineClassroom.arel_table[:classroom_id])
              )
          )
          .join_sources
      )
      .where(TeacherDisciplineClassroom.arel_table[:teacher_id]
              .eq(teacher)
            .and(TeacherDisciplineClassroom.arel_table[:active]
              .eq('t')))
      .uniq
  end

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
