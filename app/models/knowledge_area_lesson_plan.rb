class KnowledgeAreaLessonPlan < ActiveRecord::Base
  include Audit
  include Filterable

  acts_as_copy_target

  audited
  has_associated_audits

  belongs_to :lesson_plan, dependent: :destroy

  accepts_nested_attributes_for :lesson_plan

  scope :by_unity_id, lambda { |unity_id| joins(:lesson_plan).where(lesson_plans: { unity_id: unity_id }) }
  scope :by_teacher_id, lambda { |teacher_id| by_teacher_id_query(teacher_id) }
  scope :by_classroom_id, lambda { |classroom_id| joins(:lesson_plan).where(lesson_plans: { classroom_id: classroom_id }) }
  scope :by_lesson_plan_date, lambda { |lesson_plan_date| joins(:lesson_plan).where(lesson_plans: { lesson_plan_date: lesson_plan_date }) }
  scope :ordered, -> { joins(:lesson_plan).order(LessonPlan.arel_table[:lesson_plan_date].desc) }

  validates :lesson_plan, presence: true

  validate :uniqueness_of_knowledge_area_lesson_plan

  private

  def self.by_teacher_id_query(teacher_id)
    joins(
      :lesson_plan,
      arel_table.join(TeacherDisciplineClassroom.arel_table, Arel::Nodes::OuterJoin)
        .on(
          TeacherDisciplineClassroom.arel_table[:classroom_id]
            .eq(LessonPlan.arel_table[:classroom_id])
        )
        .join_sources
      )
      .where(TeacherDisciplineClassroom.arel_table[:teacher_id].eq(teacher_id))
  end

  def uniqueness_of_knowledge_area_lesson_plan
    return unless lesson_plan.present? && lesson_plan.classroom.present?
    
    knowledge_area_lesson_plans = KnowledgeAreaLessonPlan.by_classroom_id(lesson_plan.classroom_id)
      .by_lesson_plan_date(lesson_plan.lesson_plan_date)

    knowledge_area_lesson_plans = knowledge_area_lesson_plans.where.not(id: id) if persisted?

    if knowledge_area_lesson_plans.any?
        errors.add(:lesson_plan, :uniqueness_of_knowledge_area_lesson_plan)
        lesson_plan.errors.add(:lesson_plan_date, :uniqueness_of_knowledge_area_lesson_plan)
    end
  end
end
