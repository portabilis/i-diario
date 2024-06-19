class SchoolCalendarEvent < ApplicationRecord
  acts_as_copy_target

  audited
  has_associated_audits

  include Audit

  belongs_to :school_calendar_event_batch, foreign_key: 'batch_id'
  belongs_to :school_calendar
  belongs_to :grade
  belongs_to :classroom
  belongs_to :discipline
  belongs_to :course
  delegate :unity_id, to: :school_calendar

  has_enumeration_for :event_type, with: EventTypes
  has_enumeration_for :coverage, with: EventCoverageType

  validates_date :start_date, :end_date
  validates :description, :event_type, :start_date, :end_date, :school_calendar_id, presence: true
  validates :periods, presence: true, unless: :coverage_by_classroom?
  validates :course, presence: true, if: :should_validate_grade?
  validates :grade, presence: true, if: :should_validate_grade?
  validates :course, presence: true, if: :should_validate_course?
  validates :classroom, presence: true, if: :should_validate_classroom?
  validates :legend, presence: true, exclusion: { in: %w(F f N n .) }, if: :should_validate_legend?
  validate :no_retroactive_dates
  validate :uniqueness_of_start_at_in_grade
  validate :uniqueness_of_end_at_in_grade
  validate :uniqueness_of_start_at_in_classroom
  validate :uniqueness_of_end_at_in_classroom
  validate :uniqueness_of_start_at_in_course
  validate :uniqueness_of_end_at_in_course
  validate :uniqueness_of_start_at_and_end_at
  validate :start_at_and_end_at_in_step

  scope :ordered, -> { order(arel_table[:start_date]) }
  scope :school_event, -> { where(event_type: [EventTypes::EXTRA_SCHOOL, EventTypes::EXTRA_SCHOOL_WITHOUT_FREQUENCY]) }
  scope :no_school_event, lambda {
    where(event_type: [EventTypes::NO_SCHOOL_WITH_FREQUENCY, EventTypes::NO_SCHOOL])
  }
  scope :extra_school_without_frequency, -> { where(event_type: EventTypes::EXTRA_SCHOOL_WITHOUT_FREQUENCY) }
  scope :events_to_report, -> { where(event_type: [EventTypes::NO_SCHOOL, EventTypes::EXTRA_SCHOOL_WITHOUT_FREQUENCY]) }
  scope :events_with_frequency, -> { where(event_type: [EventTypes::EXTRA_SCHOOL, EventTypes::NO_SCHOOL_WITH_FREQUENCY]) }
  scope :without_grade, -> { where(arel_table[:grade_id].eq(nil)) }
  scope :without_classroom, -> { where(arel_table[:classroom_id].eq(nil)) }
  scope :without_discipline, -> { where(arel_table[:discipline_id].eq(nil)) }
  scope :without_course, -> { where(arel_table[:course_id].eq(nil)) }
  scope :by_period, ->(period) { where(' ? = ANY (periods)', period) }
  scope :by_date, lambda { |date|
    where('school_calendar_events.start_date <= ? and school_calendar_events.end_date >= ?', date.to_date, date.to_date)
  }
  scope :by_date_between, lambda { |start_at, end_at|
    where(
      'school_calendar_events.start_date >= ? and school_calendar_events.end_date <= ?',
      start_at.to_date, end_at.to_date
    )
  }
  scope :by_description, lambda { |description|
    where('unaccent(school_calendar_events.description) ILIKE unaccent(?)', '%'+description+'%')
  }
  scope :by_type, ->(type) { where(event_type: type) }
  scope :by_grade, ->(grade) { where(grade_id: grade) }
  scope :by_classroom, lambda { |classroom|
    joins(:classroom).where('unaccent(classrooms.description) ILIKE unaccent(?)', '%'+classroom+'%')
  }
  scope :by_classroom_id, ->(classroom_id) { where(classroom_id: classroom_id) }
  scope :by_discipline_id, ->(discipline_id) { where(discipline_id: discipline_id) }
  scope :by_course, ->(course_id) { where(course_id: course_id) }
  scope :all_events_for_classroom, ->(classroom) { all_events_for_classroom(classroom) }

  before_create :before_create
  before_destroy :before_destroy

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

  def before_create
    SchoolDayChecker.new(self.school_calendar, self.start_date, nil , nil , nil).create(self)
  end

  def before_destroy
    SchoolDayChecker.new(self.school_calendar, self.start_date, nil , nil , nil).destroy(self)
  end

  def self.all_events_for_classroom(classroom)
    where('? = ANY (periods) OR classroom_id = ?', classroom.period, classroom.id).
    where('grade_id IS NULL OR grade_id IN (?)', classroom.grade_ids).
    where('course_id IS NULL OR course_id IN (?)', classroom.courses.map(&:id))
    where(' "school_calendar_events"."id" in (
            SELECT id
            FROM school_calendar_events sce
            WHERE sce.start_date >= "school_calendar_events"."start_date"
            AND sce.end_date <= "school_calendar_events"."end_date"
            AND sce.school_calendar_id = "school_calendar_events"."school_calendar_id"
            AND ((? = ANY (periods) AND classroom_id IS NULL) OR classroom_id = ?)
            AND (grade_id IS NULL OR grade_id IN (?))
            AND (course_id iS NULL or course_id IN (?))
            ORDER BY COALESCE(classroom_id, 0) DESC, COALESCE(grade_id,0) DESC
            )', classroom.period, classroom.id, classroom.grade_ids, classroom.courses.map(&:id))
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
    [EventTypes::EXTRA_SCHOOL, EventTypes::NO_SCHOOL_WITH_FREQUENCY].exclude?(event_type)
  end

  def uniqueness_of_start_at_in_grade
    return unless event_type && start_date && grade && coverage == EventCoverageType::BY_GRADE

    query = school_calendar.events.where(self.class.arel_table[:event_type].not_eq(self.event_type))
    query = query.by_date(start_date)
    query = query.where(grade_id: self.grade_id)
    query = query.where(classroom_id: nil)
    query = query.where.not(id: id)

    errors.add(:start_date, :already_exists_event_in_this_date) if query.any?
  end

  def uniqueness_of_end_at_in_grade
    return unless event_type && end_date && grade && coverage == EventCoverageType::BY_GRADE

    query = school_calendar.events.where(self.class.arel_table[:event_type].not_eq(self.event_type))
    query = query.by_date(end_date)
    query = query.where(grade_id: self.grade_id)
    query = query.where(classroom_id: nil)
    query = query.where.not(id: id)

    errors.add(:end_date, :already_exists_event_in_this_date) if query.any?
  end

  def uniqueness_of_start_at_in_classroom
    return unless event_type && start_date && end_date && classroom && coverage == EventCoverageType::BY_CLASSROOM

    query = school_calendar.events.where(self.class.arel_table[:event_type].not_eq(self.event_type))
    query = query.by_date(start_date)
    query = query.where(classroom_id: self.classroom_id)
    query = query.where.not(id: id)

    errors.add(:start_date, :already_exists_event_in_this_date) if query.any?
  end

  def uniqueness_of_end_at_in_classroom
    return unless event_type && start_date && end_date && classroom && coverage == EventCoverageType::BY_CLASSROOM

    query = school_calendar.events.where(self.class.arel_table[:event_type].not_eq(self.event_type))
    query = query.by_date(end_date)
    query = query.where(classroom_id: self.classroom_id)
    query = query.where.not(id: id)

    errors.add(:end_date, :already_exists_event_in_this_date) if query.any?
  end

  def uniqueness_of_start_at_in_course
    return unless event_type && start_date && course && coverage == EventCoverageType::BY_COURSE

    query = school_calendar.events.where(self.class.arel_table[:event_type].not_eq(self.event_type))
    query = query.by_date(start_date)
    query = query.where(course_id: self.course_id)
    query = query.where(classroom_id: nil)
    query = query.where(grade_id: nil)
    query = query.where.not(id: id)

    errors.add(:start_date, :already_exists_event_in_this_date) if query.any?
  end

  def uniqueness_of_end_at_in_course
    return unless event_type && end_date && course && coverage == EventCoverageType::BY_COURSE

    query = school_calendar.events.where(self.class.arel_table[:event_type].not_eq(self.event_type))
    query = query.by_date(end_date)
    query = query.where(course_id: self.course_id)
    query = query.where(classroom_id: nil)
    query = query.where(grade_id: nil)
    query = query.where.not(id: id)

    errors.add(:end_date, :already_exists_event_in_this_date) if query.any?
  end

  def no_retroactive_dates
    return unless start_date && end_date

    if start_date > end_date
      errors.add(:start_date, 'deve ser menor que a data final')
      errors.add(:end_date, 'deve ser maior ou igual a data inicial')
    end
  end

  def start_at_and_end_at_in_step
    return if school_calendar.nil?
    return if errors[:start_date].any? || errors[:end_date].any?

    start_date_in_any_step = false
    end_date_in_any_step = false

    school_calendar.steps.each do |step|
      start_date_in_step = start_date.between?(step.start_at, step.end_at)
      end_date_in_step = end_date.between?(step.start_at, step.end_at)
      start_date_in_any_step = true if start_date_in_step
      end_date_in_any_step = true if end_date_in_step

      break if start_date_in_step && end_date_in_step
    end

    errors.add(:start_date, I18n.t('errors.messages.is_not_between_steps')) unless start_date_in_any_step
    errors.add(:end_date, I18n.t('errors.messages.is_not_between_steps')) unless end_date_in_any_step
  end

  def uniqueness_of_start_at_and_end_at
    #TODO: Mover todas as Validations acima para o Fetcher
    start_at_and_end_at = SchoolCalenderEventService.new(self).uniqueness_start_at_and_end_at

    if start_at_and_end_at[:start_date_at]
      errors.add(:start_date, I18n.t('errors.messages.uniqueness_of_start_at_and_end_at'))
    end

    if start_at_and_end_at[:end_date_at]
      errors.add(:end_date, I18n.t('errors.messages.uniqueness_of_end_at_and_start_at'))
    end
  end
end
