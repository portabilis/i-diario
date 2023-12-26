class KnowledgeAreaLessonPlan < ActiveRecord::Base
  include Audit
  include Filterable
  include TeacherRelationable
  include Translatable

  teacher_relation_columns only: :knowledge_areas

  acts_as_copy_target

  audited
  has_associated_audits

  belongs_to :lesson_plan, dependent: :destroy

  before_destroy :valid_for_destruction?

  has_many :knowledge_area_lesson_plan_knowledge_areas, dependent: :destroy
  has_many :knowledge_areas, through: :knowledge_area_lesson_plan_knowledge_areas

  delegate :contents, :objectives, :classroom, to: :lesson_plan

  accepts_nested_attributes_for :lesson_plan

  scope :by_teacher_id, ->(teacher_id) { joins(:lesson_plan).where(lesson_plans: { teacher_id: teacher_id }) }
  scope :by_other_teacher_id, lambda { |teacher_id|
    joins(:lesson_plan).where.not(lesson_plans: { teacher_id: teacher_id })
  }
  scope :by_classroom_id, lambda { |classroom_id|
    joins(:lesson_plan).where(lesson_plans: { classroom_id: classroom_id })
  }
  scope :by_knowledge_area_id, lambda { |knowledge_area_id|
    joins(:knowledge_area_lesson_plan_knowledge_areas).where(
      knowledge_area_lesson_plan_knowledge_areas: { knowledge_area_id: knowledge_area_id }
    )
  }
  scope :by_date, ->(date) { by_date_query(date) }
  scope :by_experience_fields, lambda { |experience_field|
    where('unaccent(knowledge_area_lesson_plans.experience_fields) ILIKE unaccent(?)', "%#{experience_field}%")
  }
  scope :by_date_range, lambda { |start_at, end_at|
    joins(:lesson_plan).where('start_at <= ? AND end_at >= ?', end_at.to_date, start_at.to_date)
  }
  scope :order_by_classrooms, -> { joins(lesson_plan: :classroom).order(Classroom.arel_table[:description].desc) }
  scope :ordered, -> { joins(:lesson_plan).order(LessonPlan.arel_table[:start_at].desc) }
  scope :order_by_lesson_plan_date, -> { joins(:lesson_plan).order(LessonPlan.arel_table[:start_at]) }
  scope :by_author, lambda { |author_type, current_teacher_id|
    if author_type == PlansAuthors::MY_PLANS
      joins(:lesson_plan).merge(LessonPlan.where(teacher_id: current_teacher_id))
    else
      joins(:lesson_plan).merge(LessonPlan.where.not(teacher_id: current_teacher_id))
    end
  }

  validates :lesson_plan, presence: true
  validates :knowledge_area_ids, presence: true

  def knowledge_area_ids
    knowledge_areas.collect(&:id).join(',')
  end

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

  def valid_for_destruction?
    @valid_for_destruction if defined?(@valid_for_destruction)
    @valid_for_destruction = begin
      lesson_plan.valid?
      forbidden_error = I18n.t('errors.messages.not_allowed_to_post_in_date')
      if lesson_plan.errors[:start_at].include?(forbidden_error) || lesson_plan.errors[:end_at].include?(forbidden_error)
        errors.add(:base, forbidden_error)
        false
      else
        true
      end
    end
  end
end
