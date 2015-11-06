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
  scope :by_teacher_id, lambda { |teacher_id| by_teacher_id_query(teacher_id) }
  scope :by_classroom_id, lambda { |classroom_id| joins(:lesson_plan).where(lesson_plans: { classroom_id: classroom_id }) }
  scope :by_discipline_id, lambda { |discipline_id| where(discipline_id: discipline_id) }
  scope :by_lesson_plan_date, lambda { |lesson_plan_date| joins(:lesson_plan).where(lesson_plans: { lesson_plan_date: lesson_plan_date }) }
  scope :by_classes, lambda { |classes| where("classes && ARRAY#{classes}::INTEGER[]") }
  scope :by_discipline_id_lesson_plan_date, lambda {|discipline_id, date_start, date_end, classroom_id| joins(:lesson_plan).where("case when ? = 0 then 1=1 else discipline_id = ? end
             and case when ? = 0 then 1 = 1 else classroom_id = ? end
             and case when ? = '01/01/1900' then  1=1 when ? = '01/01/1900' then  1=1  else lesson_plan_date between ? and ? end",
             (discipline_id == '' ? 0 : discipline_id), (discipline_id == '' ? 0 : discipline_id), (classroom_id == '' ? 0 : classroom_id), 
             (classroom_id == '' ? 0 : classroom_id), (date_start == '' ? '01/01/1900' : date_start), 
             (date_end == '' ? '01/01/1900' : date_end), (date_start == '' ? '01/01/1900' : date_start), (date_end == '' ? '01/01/1900' : date_end)).order("lesson_plan_date ASC")}
  scope :by_date_start_between, lambda {|date_start, date_end| joins(:lesson_plan).where(lesson_plans: { lesson_plan_date: date_start..date_end})}
  scope :ordered, -> { joins(:lesson_plan).order(LessonPlan.arel_table[:lesson_plan_date].desc) }

  validates :lesson_plan, presence: true
  validates :discipline, presence: true
  validates :classes, presence: true, if: :require_classes?

  validate :uniqueness_of_discipline_lesson_plan

  def classes=(classes)
    write_attribute(:classes, classes ? classes.split(',').sort.map(&:to_i) : classes)
  end

  private

  def self.by_teacher_id_query(teacher_id)
    joins(
      :lesson_plan,
      arel_table.join(TeacherDisciplineClassroom.arel_table, Arel::Nodes::OuterJoin)
        .on(
          TeacherDisciplineClassroom.arel_table[:classroom_id]
            .eq(LessonPlan.arel_table[:classroom_id])
            .and(
              TeacherDisciplineClassroom.arel_table[:discipline_id]
                .eq(arel_table[:discipline_id])
            )
        )
        .join_sources
      )
      .where(TeacherDisciplineClassroom.arel_table[:teacher_id].eq(teacher_id))
  end

  def require_classes?
    return unless lesson_plan.present? && lesson_plan.classroom.present?

    lesson_plan.classroom.exam_rule.frequency_type == FrequencyTypes::BY_DISCIPLINE
  end

  def uniqueness_of_discipline_lesson_plan
    return unless lesson_plan.present? && lesson_plan.classroom.present?

    discipline_lesson_plans = DisciplineLessonPlan.by_classroom_id(lesson_plan.classroom_id)
      .by_discipline_id(discipline_id)
      .by_lesson_plan_date(lesson_plan.lesson_plan_date)

    discipline_lesson_plans = discipline_lesson_plans.by_classes(classes) if classes.present?
    discipline_lesson_plans = discipline_lesson_plans.where.not(id: id) if persisted?

    if classes.present?
      errors.add(:classes, :uniqueness_of_discipline_lesson_plan, count: classes.count) if discipline_lesson_plans.any?
    else
      if discipline_lesson_plans.any?
        errors.add(:lesson_plan, :uniqueness_of_discipline_lesson_plan)
        lesson_plan.errors.add(:lesson_plan_date, :uniqueness_of_discipline_lesson_plan)
      end
    end
  end
end
