# encoding: utf-8
class SchoolCalendarEvent < ActiveRecord::Base
  acts_as_copy_target

  audited
  has_associated_audits

  include Audit
  include Filterable

  attr_accessor :course_id

  belongs_to :school_calendar
  belongs_to :grade
  belongs_to :classroom
  has_one :course, through: :grade

  has_enumeration_for :event_type, with: EventTypes
  has_enumeration_for :coverage, with: CoveragesOfEvent

  validates :description, :event_type, :event_date, :school_calendar_id, presence: true
  validates :grade, presence: true, if: :should_validate_grade?
  validates :classroom, presence: true, if: :should_validate_classroom?
  validate :uniquenesss_of_event_in_grade
  validate :uniquenesss_of_event_in_classroom

  scope :ordered, -> { order(arel_table[:event_date]) }
  scope :by_date, lambda { |date| where(event_date: date.to_date) }
  scope :by_description, lambda { |description| where('description ILIKE ?', '%'+description+'%') }
  scope :by_type, lambda { |type| where(event_type: type) }
  scope :by_grade, lambda { |grade| where(grade_id: grade) }
  scope :by_classroom, lambda { |classroom| joins(:classroom).where('classrooms.description ILIKE ?', '%'+classroom+'%') }

  def to_s
    description
  end

  protected

  def should_validate_grade?
    [CoveragesOfEvent::BY_GRADE, CoveragesOfEvent::BY_CLASSROOM].include? self.coverage
  end

  def should_validate_classroom?
    self.coverage == CoveragesOfEvent::BY_CLASSROOM
  end

  def uniquenesss_of_event_in_grade
    return unless event_type && event_date && grade && coverage == CoveragesOfEvent::BY_GRADE
    query = school_calendar.events.where(self.class.arel_table[:event_type].not_eq(self.event_type))
    query = query.where(event_date: self.event_date)
    query = query.where(grade_id: self.grade_id)
    query = query.where(classroom_id: nil)
    errors.add(:event_date, "Já existe um evento cadastrado de outro tipo nesta data") if query.any?
  end

  def uniquenesss_of_event_in_classroom
    return unless event_type && event_date && classroom && coverage == CoveragesOfEvent::BY_CLASSROOM
    query = school_calendar.events.where(self.class.arel_table[:event_type].not_eq(self.event_type))
    query = query.where(event_date: self.event_date)
    query = query.where(classroom_id: self.classroom_id)
    errors.add(:event_date, "Já existe um evento cadastrado de outro tipo nesta data") if query.any?
  end
end
