class LessonPlan < ActiveRecord::Base
  acts_as_copy_target

  audited
  has_associated_audits

  include Audit
  include Filterable

  belongs_to :unity
  belongs_to :classroom
  belongs_to :discipline
  belongs_to :school_calendar

  has_many :teacher_discipline_classrooms, -> { where(TeacherDisciplineClassroom.arel_table[:discipline_id].eq(Content.arel_table[:discipline_id])) }, through: :classroom

  validates :unity, :classroom, :school_calendar,  :lesson_plan_date, :contents, presence: true
  validates :classes, presence: true, if: :classroom_required?

  validate :is_school_day?
  validate :uniqueness_of_lesson_plan

  scope :by_teacher_id, (lambda do |teacher_id|
      joins(
        arel_table.join(TeacherDisciplineClassroom.arel_table, Arel::Nodes::OuterJoin)
          .on(
            TeacherDisciplineClassroom.arel_table[:classroom_id].eq(arel_table[:classroom_id])
              .and(TeacherDisciplineClassroom.arel_table[:discipline_id].eq(arel_table[:discipline_id]).or(arel_table[:discipline_id].eq(nil)))
          )
          .join_sources
      )
      .where(TeacherDisciplineClassroom.arel_table[:teacher_id].eq(teacher_id))
      .uniq
    end)
  scope :by_unity_id, lambda { |unity_id| where unity_id: unity_id }
  scope :by_classroom_id, lambda { |classroom_id| where classroom_id: classroom_id }
  scope :by_discipline_id, lambda { |discipline_id| where discipline_id: discipline_id }
  scope :by_lesson_plan_date, lambda { |lesson_plan_date| where(lesson_plan_date: lesson_plan_date) }
  scope :by_classes, lambda { |classes| where("classes && ARRAY#{classes}::INTEGER[]") }

  scope :ordered, -> { order(arel_table[:lesson_plan_date]) }

  def to_s
    description
  end

  def classes=(classes)
    write_attribute(:classes, classes ? classes.split(',').sort.map(&:to_i) : classes)
  end

  private

  def classroom_required?
    if (ExamRule.by_id(classroom == nil ? 0 : classroom.exam_rule_id ).by_frequency_type '1') == []
      return true
    end
  end

  def is_school_day?
    return unless school_calendar && lesson_plan_date

    errors.add(:lesson_plan_date, :must_be_school_day) if !school_calendar.school_day? lesson_plan_date
  end

  def uniqueness_of_lesson_plan
    if discipline_id.present?
      lesson_plans = LessonPlan.by_classroom_id(classroom_id)
        .by_discipline_id(discipline_id)
        .by_lesson_plan_date(lesson_plan_date)
        .by_classes(classes)

      lesson_plans = lesson_plans.where.not(id: id) if persisted?

      errors.add(:classes, :uniqueness_of_lesson_plan, count: classes.count) if lesson_plans.any?
    else
      lesson_plans = LessonPlan.by_classroom_id(classroom_id)
        .by_lesson_plan_date(lesson_plan_date)

      lesson_plans = lesson_plans.where.not(id: id) if persisted?

      errors.add(:lesson_plan_date, :uniqueness_of_lesson_plan) if lesson_plans.any?
    end
  end
end
