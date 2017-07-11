class LessonPlan < ActiveRecord::Base
  include Audit

  acts_as_copy_target

  attr_writer :contents_tags

  audited except: [:teacher_id, :old_contents]
  has_associated_audits

  belongs_to :school_calendar
  belongs_to :classroom

  has_one :discipline_lesson_plan
  has_one :knowledge_area_lesson_plan

  has_many :contents_lesson_plans, dependent: :destroy
  has_many :contents, through: :contents_lesson_plans
  has_many :lesson_plan_attachments, dependent: :destroy

  accepts_nested_attributes_for :contents, allow_destroy: true
  accepts_nested_attributes_for :lesson_plan_attachments, allow_destroy: true

  validates :school_calendar, presence: true
  validates :unity, presence: true
  validates :classroom, presence: true
  validates :start_at, presence: true
  validates :end_at, presence: true

  validate :crescent_date_range
  validate :at_least_one_assigned_content

  delegate :unity, :unity_id, to: :classroom

  scope :by_unity_id, lambda { |unity_id| joins(:classroom).merge(Classroom.by_unity(unity_id)) }
  scope :by_teacher_id, lambda { |teacher_id| where(teacher_id: teacher_id) }
  scope :current, -> { where("current_date BETWEEN start_at and end_at") }
  scope :ordered, -> { joins(:classroom).order('description ASC') }

  def to_s
    discipline_lesson_plan.discipline.to_s
  end

  def contents_tags
    if @contents_tags.present?
      ContentTagConverter::tags_to_json(@contents_tags)
    else
      ContentTagConverter::contents_to_json(contents_ordered)
    end
  end

  def contents_ordered
    contents.order(' "contents_lesson_plans"."id" ')
  end

  private

  def crescent_date_range
    return if start_at.nil? or end_at.nil?
    if start_at > end_at
      errors.add(:start_at)
      errors.add(:end_at)
      errors.add(:base, :crescent_date_range)
    end
  end

  def at_least_one_assigned_content
    errors.add(:contents, :at_least_one_content) if contents.empty?
  end
end
