class LessonPlan < ApplicationRecord
  include Audit
  include TeacherRelationable
  include Translatable

  teacher_relation_columns only: :classroom

  acts_as_copy_target

  attr_accessor :grade_ids, :contents_created_at_position, :objectives_created_at_position
  attr_writer :contents_tags

  audited except: [:teacher_id, :old_contents]
  has_associated_audits

  belongs_to :school_calendar
  belongs_to :classroom
  belongs_to :teacher

  has_one :discipline_lesson_plan
  has_one :knowledge_area_lesson_plan

  has_many :contents_lesson_plans, dependent: :destroy
  deferred_has_many :contents, through: :contents_lesson_plans
  has_many :objectives_lesson_plans, dependent: :destroy
  deferred_has_many :objectives, through: :objectives_lesson_plans
  has_many :lesson_plan_attachments, dependent: :destroy

  accepts_nested_attributes_for :contents, allow_destroy: true
  accepts_nested_attributes_for :lesson_plan_attachments, allow_destroy: true

  validates_date :start_at, :end_at
  validates :school_calendar, presence: true
  validates :unity, presence: true
  validates :classroom, presence: true
  validates :start_at, presence: true, school_calendar_day: true, posting_date: true
  validates :end_at, presence: true, school_calendar_day: true, posting_date: true

  validate :no_retroactive_dates
  validate :at_least_one_assigned_content
  validate :valid_attachments_size

  delegate :unity, :unity_id, to: :classroom, allow_nil: true
  delegate :grades, :grade_ids, :first_grade, to: :classroom, allow_nil: true

  scope :by_unity_id, lambda { |unity_id| joins(:classroom).merge(Classroom.by_unity(unity_id)) }
  scope :by_teacher_id, lambda { |teacher_id| where(teacher_id: teacher_id) }
  scope :current, -> { where("current_date BETWEEN start_at and end_at") }
  scope :ordered, -> { joins(:classroom).order('description ASC') }

  def self.fromLastDays days
    start_date = (Date.current - days.days).to_date
    where('start_at <= current_date AND end_at >= ? ', start_date)
  end

  def to_s
    return discipline_lesson_plan.discipline.to_s if discipline_lesson_plan
    return knowledge_area_lesson_plan.knowledge_areas.ordered.first.to_s if knowledge_area_lesson_plan
  end

  def contents_tags
    if @contents_tags.present?
      ContentTagConverter::tags_to_json(@contents_tags)
    else
      ContentTagConverter::contents_to_json(contents_ordered)
    end
  end

  def contents_ordered
    contents.order('contents_lesson_plans.position')
  end

  def objectives_ordered
    objectives.order('objectives_lesson_plans.position')
  end

  def attachments?
    lesson_plan_attachments.any?
  end

  private

  def valid_attachments_size
    return if total_attatchments_size < 30000000

    errors.add(:lesson_plan_attachments,
               'A soma do tamanho dos arquivos anexados ' +
               'de uma vez não pode ultrapassar 30MB, ' +
               'revise os arquivos e tente novamente')
  end

  def total_attatchments_size
    lesson_plan_attachments
      .map(&:attachment)
      .compact
      .map{ |attachment| attachment.file&.size }
      .compact
      .inject(:+)
      .to_i
  end

  def no_retroactive_dates
    return if start_at.nil? || end_at.nil?

    if start_at > end_at
      errors.add(:start_at, 'não pode ser maior que a Data final')
      errors.add(:end_at, 'deve ser maior ou igual a Data inicial')
    end
  end

  def at_least_one_assigned_content
    return unless contents_empty?

    errors.add(:contents, :at_least_one_content)
  end

  def contents_empty?
    contents.empty? || (contents.size == contents.select(&:marked_for_destruction?).size)
  end
end
