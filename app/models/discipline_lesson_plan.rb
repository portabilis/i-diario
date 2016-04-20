class DisciplineLessonPlan < ActiveRecord::Base
  include Audit
  include Filterable

  acts_as_copy_target

  audited
  has_associated_audits

  belongs_to :lesson_plan, dependent: :destroy
  belongs_to :discipline

  accepts_nested_attributes_for :lesson_plan

  scope :by_unity_id, lambda { |unity_id| joins(:lesson_plan).where(lesson_plans: { unity_id: unity_id }) }
  scope :by_teacher_id, lambda { |teacher_id| joins(:lesson_plan).where(lesson_plans: { teacher_id: teacher_id }) }
  scope :by_classroom_id, lambda { |classroom_id| joins(:lesson_plan).where(lesson_plans: { classroom_id: classroom_id }) }
  scope :by_discipline_id, lambda { |discipline_id| where(discipline_id: discipline_id) }
  scope :by_date, lambda { |date| by_date_query(date) }
  scope :by_date_range, lambda { |start_at, end_at| joins(:lesson_plan).where("start_at <= ? AND end_at >= ?", end_at, start_at) }
  scope :ordered, -> { joins(:lesson_plan).order(LessonPlan.arel_table[:start_at].desc) }

  validates :lesson_plan, presence: true
  validates :discipline, presence: true

  validate :uniqueness_of_discipline_lesson_plan

  private

  def self.by_date_query(date)
    date = date.to_date
    joins(:lesson_plan)
      .where(
        LessonPlan.arel_table[:start_at]
          .lteq(date)
          .and(LessonPlan.arel_table[:end_at].gteq(date))
      )
  end

  def uniqueness_of_discipline_lesson_plan
    return unless lesson_plan.present? && lesson_plan.classroom.present?

    discipline_lesson_plans = DisciplineLessonPlan.by_classroom_id(lesson_plan.classroom_id)
      .by_discipline_id(discipline_id)
      .by_date_range(lesson_plan.start_at, lesson_plan.end_at)

    discipline_lesson_plans = discipline_lesson_plans.where.not(id: id) if persisted?

    if discipline_lesson_plans.any?
      lesson_plan.errors.add(:start_at)
      lesson_plan.errors.add(:end_at)
      lesson_plan.errors.add(:base, :uniqueness_of_discipline_lesson_plan)
      errors.add(:base, :uniqueness_of_discipline_lesson_plan)
    end
  end

end
