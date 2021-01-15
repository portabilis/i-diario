class ContentRecord < ActiveRecord::Base
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

  has_one :discipline_content_record, dependent: :delete
  has_one :knowledge_area_content_record, dependent: :delete
  has_many :content_records_contents, dependent: :destroy
  deferred_has_many :contents, through: :content_records_contents

  accepts_nested_attributes_for :contents

  validates_date :record_date, on_or_before: -> { Date.current }
  validates :unity_id, presence: true
  validates :classroom, presence: true
  validates :record_date, presence: true, school_calendar_day: true, posting_date: true
  validates :teacher, presence: true
  validate :at_least_one_content

  delegate :grade_id, to: :classroom
  delegate :grade, :grade_id, to: :classroom

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
end
