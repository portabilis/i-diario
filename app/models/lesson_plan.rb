class LessonPlan < ActiveRecord::Base
  include Audit

  acts_as_copy_target

  attr_writer :contents_tags
  attr_accessor :start_at_copy, :end_at_copy

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
  validates :start_at, presence: true, school_calendar_day: true
  validates :end_at, presence: true, school_calendar_day: true

  validate :no_retroactive_dates
  validate :at_least_one_assigned_content
  validate :start_at_valid, :end_at_valid

  delegate :unity, :unity_id, to: :classroom

  scope :by_unity_id, lambda { |unity_id| joins(:classroom).merge(Classroom.by_unity(unity_id)) }

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

  def no_retroactive_dates
    return if start_at.nil? || end_at.nil?

    if start_at > end_at
      errors.add(:start_at, 'não pode ser maior que a Data final')
      errors.add(:end_at, 'deve ser maior ou igual a Data inicial')
    end
  end

  def at_least_one_assigned_content
    errors.add(:contents, :at_least_one_content) if contents.empty?
  end

  # necessario pois quando inserida uma data invalida, o controller considera
  # o valor de start_at e end_at como nil e a mensagem mostrada é a de que não pode
  # ficar em branco, quando deve mostrar a de que foi inserida uma data invalida
  def start_at_valid
    return if start_at_copy.nil?
    begin
      start_at_copy.to_date
    rescue ArgumentError
      errors[:start_at].clear
      errors.add(:start_at, "deve ser uma data válida")
    end
  end

  def end_at_valid
    return if end_at_copy.nil?
    begin
      end_at_copy.to_date
    rescue ArgumentError
      errors[:end_at].clear
      errors.add(:end_at, "deve ser uma data válida")
    end
  end
end
