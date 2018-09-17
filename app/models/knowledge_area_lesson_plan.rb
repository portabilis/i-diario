class KnowledgeAreaLessonPlan < ActiveRecord::Base
  include Audit
  include Filterable

  acts_as_copy_target

  audited
  has_associated_audits

  belongs_to :lesson_plan, dependent: :destroy

  before_destroy :remove_attachments

  has_many :knowledge_area_lesson_plan_knowledge_areas, dependent: :destroy
  has_many :knowledge_areas, through: :knowledge_area_lesson_plan_knowledge_areas

  delegate :contents, :classroom, to: :lesson_plan

  accepts_nested_attributes_for :lesson_plan

  scope :by_teacher_id, lambda { |teacher_id| joins(:lesson_plan).where(lesson_plans: { teacher_id: teacher_id }) }
  scope :by_classroom_id, lambda { |classroom_id| joins(:lesson_plan).where(lesson_plans: { classroom_id: classroom_id }) }
  scope :by_knowledge_area_id, lambda { |knowledge_area_id| joins(:knowledge_area_lesson_plan_knowledge_areas).where(knowledge_area_lesson_plan_knowledge_areas: { knowledge_area_id: knowledge_area_id }) }
  scope :by_date, lambda { |date| by_date_query(date) }
  scope :by_date_range, lambda { |start_at, end_at| joins(:lesson_plan).where("start_at <= ? AND end_at >= ?", end_at, start_at) }

  scope :ordered, -> { joins(:lesson_plan).order(LessonPlan.arel_table[:start_at].desc) }
  scope :order_by_lesson_plan_date, -> { joins(:lesson_plan).order(LessonPlan.arel_table[:start_at]) }

  validates :lesson_plan, presence: true
  validates :knowledge_area_ids, presence: true

  validate :uniqueness_of_knowledge_area_lesson_plan

  def knowledge_area_ids
    knowledge_areas.collect(&:id).join(',')
  end

  private

  def uniqueness_of_knowledge_area_lesson_plan
    return unless lesson_plan.present? && lesson_plan.classroom.present?

    knowledge_area_lesson_plans = KnowledgeAreaLessonPlan.by_classroom_id(lesson_plan.classroom_id)
      .by_knowledge_area_id(knowledge_areas.collect(&:id))
      .by_date_range(lesson_plan.start_at, lesson_plan.end_at)
      .by_teacher_id(lesson_plan.teacher_id)

    knowledge_area_lesson_plans = knowledge_area_lesson_plans.where.not(id: id) if persisted?

    if knowledge_area_lesson_plans.any?
        errors.add(:knowledge_area_ids, :uniqueness_of_knowledge_area_lesson_plan, count: knowledge_areas.split(',').count)
    end
  end

  def self.by_date_query(date)
    date = date.to_date
    joins(:lesson_plan)
      .where(
        LessonPlan.arel_table[:start_at]
          .lteq(date)
          .and(LessonPlan.arel_table[:end_at].gteq(date))
      )
  end

  def remove_attachments
    lesson_plan.lesson_plan_attachments.each { |lesson_plan_attachment| lesson_plan_attachment.attachment = nil }
    lesson_plan.save
  end
end
