class ContentRecord < ApplicationRecord
  include Audit
  include ColumnsLockable
  include TeacherRelationable
  include Translatable

  not_updatable only: :classroom_id
  teacher_relation_columns only: :classroom

  audited
  has_associated_audits

  acts_as_copy_target

  belongs_to :classroom
  belongs_to :teacher

  attr_writer :unity_id
  attr_writer :contents_tags
  attr_accessor :creator_type

  has_one :discipline_content_record, dependent: :delete
  has_one :knowledge_area_content_record, dependent: :delete

  has_many :content_records_contents, dependent: :destroy
  deferred_has_many :contents, through: :content_records_contents

  accepts_nested_attributes_for :contents

  validates_date :record_date, on_or_before: -> { Date.current }
  validates :unity_id, presence: true
  validates :classroom, presence: true
  validates :record_date, presence: true, school_calendar_day: true, posting_date: true
  validates :daily_activities_record, presence: true, if: :require_daily_activities_record?
  validates :teacher, presence: true
  validate :at_least_one_content

  delegate :grades, :grade_ids, :first_grade, to: :classroom

  scope :by_unity_id, lambda { |unity_id| joins(:classroom).merge(Classroom.by_unity(unity_id)) }
  scope :by_teacher_id, lambda { |teacher_id| where(teacher_id: teacher_id) }

  def to_s
    return discipline_content_record.discipline.to_s if discipline_content_record
    return knowledge_area_content_record.knowledge_areas.first.to_s if knowledge_area_content_record
  end

  def self.fromLastDays days
    start_date = (Date.current - days.days).to_date
    where('record_date >= ? ', start_date)
  end

  def school_calendar
    return if classroom.blank?

    CurrentSchoolCalendarFetcher.new(unity, classroom, classroom.year).fetch
  end

  def unity
    return unless unity_id
    Unity.find(unity_id)
  end

  def unity_id
    classroom.try(:unity_id) || @unity_id
  end

  def contents_tags
    if @contents_tags.present?
      ContentTagConverter::tags_to_json(@contents_tags)
    end
  end

  def contents_ordered
    contents.order(' "content_records_contents"."id" ')
  end

  def origin=(value)
    return origin if persisted?

    super(value)
  end

  private

  def at_least_one_content
    if content_ids.blank?
      errors.add(:contents, :at_least_one_content)
    end
  end

  def require_daily_activities_record?
    return false if general_configuration.require_daily_activities_record_does_not_require?
    return true if general_configuration.require_daily_activities_record_always?

    require_discipline_content_records? || require_knowledge_area_content_records?
  end

  def require_discipline_content_records?
    has_discipline_content_record = discipline_content_record.present? || creator_type.eql?('discipline_content_record')
    has_discipline_content_record && general_configuration.require_daily_activities_record_on_discipline_content_records?
  end

  def require_knowledge_area_content_records?
    has_knowledge_area_content_record = knowledge_area_content_record.present? || creator_type.eql?('knowledge_area_content_record')
    has_knowledge_area_content_record && general_configuration.require_daily_activities_record_on_knowledge_area_content_records?
  end

  def general_configuration
    @general_configuration ||= GeneralConfiguration.current
  end
end
