class SchoolCalendarEvent < ActiveRecord::Base
  acts_as_copy_target

  audited
  has_associated_audits

  include Audit

  belongs_to :school_calendar
  belongs_to :grade
  belongs_to :classroom
  belongs_to :discipline
  belongs_to :course
  delegate :unity_id, to: :school_calendar

  has_enumeration_for :event_type, with: EventTypes
  has_enumeration_for :coverage, with: EventCoverageType

  validates :description, :event_type, :start_date, :end_date, :school_calendar_id, presence: true
  validates :periods, presence: true, unless: :coverage_by_classroom?
  validates :course, presence: true, if: :should_validate_grade?
  validates :grade, presence: true, if: :should_validate_grade?
  validates :course, presence: true, if: :should_validate_course?
  validates :classroom, presence: true, if: :should_validate_classroom?
  validates :legend, presence: true, exclusion: {in: %w(F f N n .) }, if: :should_validate_legend?
  validate :start_at_must_be_less_than_or_equal_to_end_at
  validate :uniquenesss_of_start_at_in_grade
  validate :uniquenesss_of_end_at_in_grade
  validate :uniquenesss_of_start_at_in_classroom
  validate :uniquenesss_of_end_at_in_classroom
  validate :uniquenesss_of_start_at_in_course
  validate :uniquenesss_of_end_at_in_course

  scope :ordered, -> { order(arel_table[:start_date]) }
  scope :with_frequency, -> { where(arel_table[:event_type].eq(EventTypes::EXTRA_SCHOOL)) }
  scope :without_frequency, -> { where(arel_table[:event_type].not_eq(EventTypes::EXTRA_SCHOOL)) }
  scope :extra_school_without_frequency, -> { where(event_type: EventTypes::EXTRA_SCHOOL_WITHOUT_FREQUENCY) }
  scope :without_grade, -> { where(arel_table[:grade_id].eq(nil) ) }
  scope :without_classroom, -> { where(arel_table[:classroom_id].eq(nil) ) }
  scope :without_discipline, -> { where(arel_table[:discipline_id].eq(nil) ) }
  scope :without_course, -> { where(arel_table[:course_id].eq(nil) ) }
  scope :by_period, lambda { |period| where(' ? = ANY (periods)', period) }
  scope :by_date, lambda { |date| where('start_date <= ? and end_date >= ?', date, date) }
  scope :by_date_between, lambda { |start_at, end_at| where('start_date >= ? and end_date <= ?', start_at.to_date, end_at.to_date) }
  scope :by_description, lambda { |description| where('description ILIKE ?', '%'+description+'%') }
  scope :by_type, lambda { |type| where(event_type: type) }
  scope :by_grade, lambda { |grade| where(grade_id: grade) }
  scope :by_classroom, lambda { |classroom| joins(:classroom).where('classrooms.description ILIKE ?', '%'+classroom+'%') }
  scope :by_classroom_id, lambda { |classroom_id| where(classroom_id: classroom_id) }
  scope :by_discipline_id, lambda { |discipline_id| where(discipline_id: discipline_id) }
  scope :by_course, lambda { |course_id| where(course_id: course_id) }
  scope :all_events_for_classroom, lambda { |classroom| all_events_for_classroom(classroom) }

  def to_s
    description
  end

  def duration
    "#{I18n.l(start_date)} à #{I18n.l(end_date)}"
  end

  def periods=(periods)
    write_attribute(:periods, periods ? periods.split(',').sort : periods)
  end

  def coverage_by_unity?
    coverage == EventCoverageType::BY_UNITY
  end

  def coverage_by_classroom?
    coverage == EventCoverageType::BY_CLASSROOM
  end

  def coverage_by_course?
    coverage == EventCoverageType::BY_COURSE
  end

  def coverage_by_grade?
    coverage == EventCoverageType::BY_GRADE
  end

  protected

  def self.all_events_for_classroom(classroom)
    where('? = ANY (periods) OR classroom_id = ?', classroom.period, classroom.id).
    where('grade_id IS NULL OR grade_id = ?', classroom.grade.id).
    where('course_id IS NULL OR course_id = ?', classroom.grade.course_id)
    where(' "school_calendar_events"."id" in (
            SELECT id
            FROM school_calendar_events sce
            WHERE sce.start_date >= "school_calendar_events"."start_date"
            AND sce.end_date <= "school_calendar_events"."end_date"
            AND sce.school_calendar_id = "school_calendar_events"."school_calendar_id"
            AND ((? = ANY (periods) AND classroom_id IS NULL) OR classroom_id = ?)
            AND (grade_id IS NULL OR grade_id = ?)
            AND (course_id iS NULL or course_id = ?)
            ORDER BY COALESCE(classroom_id, 0) DESC, COALESCE(grade_id,0) DESC
            LIMIT 1
            )', classroom.period, classroom.id, classroom.grade.id, classroom.grade.course_id)
  end

  def should_validate_grade?
    [EventCoverageType::BY_GRADE, EventCoverageType::BY_CLASSROOM].include? self.coverage
  end

  def should_validate_course?
    self.coverage_by_course?
  end

  def should_validate_classroom?
    self.coverage_by_classroom?
  end

  def should_validate_legend?
    self.event_type != EventTypes::EXTRA_SCHOOL
  end

  def uniquenesss_of_start_at_in_grade
    return unless event_type && start_date && grade && coverage == EventCoverageType::BY_GRADE
    query = school_calendar.events.where(self.class.arel_table[:event_type].not_eq(self.event_type))
    query = query.by_date(start_date)
    query = query.where(grade_id: self.grade_id)
    query = query.where(classroom_id: nil)
    query = query.where.not(id: id)

    errors.add(:start_date, :already_exists_event_in_this_date) if query.any?
  end

  def uniquenesss_of_end_at_in_grade
    return unless event_type && end_date && grade && coverage == EventCoverageType::BY_GRADE
    query = school_calendar.events.where(self.class.arel_table[:event_type].not_eq(self.event_type))
    query = query.by_date(end_date)
    query = query.where(grade_id: self.grade_id)
    query = query.where(classroom_id: nil)
    query = query.where.not(id: id)

    errors.add(:end_date, :already_exists_event_in_this_date) if query.any?
  end

  def uniquenesss_of_start_at_in_classroom
    return unless event_type && start_date && end_date && classroom && coverage == EventCoverageType::BY_CLASSROOM
    query = school_calendar.events.where(self.class.arel_table[:event_type].not_eq(self.event_type))
    query = query.by_date(start_date)
    query = query.where(classroom_id: self.classroom_id)
    query = query.where.not(id: id)

    errors.add(:start_date, :already_exists_event_in_this_date) if query.any?
  end

  def uniquenesss_of_end_at_in_classroom
    return unless event_type && start_date && end_date && classroom && coverage == EventCoverageType::BY_CLASSROOM
    query = school_calendar.events.where(self.class.arel_table[:event_type].not_eq(self.event_type))
    query = query.by_date(end_date)
    query = query.where(classroom_id: self.classroom_id)
    query = query.where.not(id: id)

    errors.add(:end_date, :already_exists_event_in_this_date) if query.any?
  end

  def uniquenesss_of_start_at_in_course
    return unless event_type && start_date && course && coverage == EventCoverageType::BY_COURSE
    query = school_calendar.events.where(self.class.arel_table[:event_type].not_eq(self.event_type))
    query = query.by_date(start_date)
    query = query.where(course_id: self.course_id)
    query = query.where(classroom_id: nil)
    query = query.where(grade_id: nil)
    query = query.where.not(id: id)

    errors.add(:start_date, :already_exists_event_in_this_date) if query.any?
  end

  def uniquenesss_of_end_at_in_course
    return unless event_type && end_date && course && coverage == EventCoverageType::BY_COURSE
    query = school_calendar.events.where(self.class.arel_table[:event_type].not_eq(self.event_type))
    query = query.by_date(end_date)
    query = query.where(course_id: self.course_id)
    query = query.where(classroom_id: nil)
    query = query.where(grade_id: nil)
    query = query.where.not(id: id)

    errors.add(:end_date, :already_exists_event_in_this_date) if query.any?
  end

  def start_at_must_be_less_than_or_equal_to_end_at
    return unless start_date && end_date

    errors.add(:end_date, "deve ser maior ou igual a Data inicial") if start_date.to_date > end_date.to_date
  end
end
