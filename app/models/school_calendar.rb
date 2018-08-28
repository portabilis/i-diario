class SchoolCalendar < ActiveRecord::Base
  acts_as_copy_target

  before_validation :self_assign_to_steps
  after_create :seed_events

  audited
  has_associated_audits

  include Audit
  include Filterable

  belongs_to :unity

  has_many :steps, -> { active.includes(:school_calendar).ordered }, class_name: 'SchoolCalendarStep', dependent: :destroy
  has_many :classrooms, class_name: 'SchoolCalendarClassroom', dependent: :destroy
  has_many :events, class_name: 'SchoolCalendarEvent', dependent: :destroy

  accepts_nested_attributes_for :steps, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :classrooms, reject_if: :all_blank, allow_destroy: true

  validates :year, presence: true, uniqueness: { scope: :unity_id }
  validates :number_of_classes, presence: true, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 1,
    less_than_or_equal_to: 10
  }

  validates_associated :steps

  scope :by_year, lambda { |year| where(year: year) }
  scope :by_unity_id, lambda { |unity_id| where(unity_id: unity_id) }
  scope :by_unity_api_code, lambda { |unity_api_code| joins(:unity).where(unities: { api_code: unity_api_code }) }
  scope :by_school_day, lambda { |date| by_school_day(date) }
  scope :by_school_day_classroom_steps, lambda { |date, classroom| by_school_day_classroom_steps(date, classroom) }
  scope :ordered, -> { joins(:unity).order(year: :desc).order('unities.name') }

  def to_s
    "#{year}"
  end

  def school_day?(date, grade_id = nil, classroom_id = nil, discipline_id = nil)
    SchoolDayChecker.new(self, date, grade_id, classroom_id, discipline_id).school_day?
  end

  def step(date)
    steps.all.started_after_and_before(date).first
  end

  def posting_step(date)
    steps.all.posting_date_after_and_before(date).first
  end

  def school_term(date)
    school_terms = { 4 => Bimesters, 3 => Trimesters, 2 => Semesters, 1 => Year }
    index_of_step = steps.find_index(step(date))

    if school_term = school_terms[steps.count]
      school_term.key_for(index_of_step)
    end
  end

  def school_step(step)
    school_terms = { 4 => Bimesters, 3 => Trimesters, 2 => Semesters, 1 => Year }
    index_of_step = steps.find_index(step)

    if school_term = school_terms[steps.size]
      school_term.key_for(index_of_step)
    end
  end

  def school_term_day?(school_term, date)
    real_school_term = school_term(date)
    real_school_term.to_sym == school_term.to_sym
  end

  def first_day
    steps.reorder(start_at: :asc).first.start_at
  end

  def last_day
    steps.reorder(start_at: :desc).first.end_at
  end

  private

  def self.by_school_day(date)
    joins(:steps).where(SchoolCalendarStep.arel_table[:start_at].lteq(date.to_date))
                 .where(SchoolCalendarStep.arel_table[:end_at].gteq(date.to_date))
  end

  def self.by_school_day_classroom_steps(date, classroom)
    joins(:classrooms).where(SchoolCalendarClassroom.arel_table[:classroom_id].eq(classroom.id))
                      .joins(classrooms: :classroom_steps)
                      .where(SchoolCalendarClassroomStep.arel_table[:start_at].lteq(date.to_date))
                      .where(SchoolCalendarClassroomStep.arel_table[:end_at].gteq(date.to_date))
  end

  def self_assign_to_steps
    steps.each { |step| step.school_calendar = self }
  end

  def seed_events
    events_seeder = SchoolCalendarEventsSeeder.new(school_calendar: self)
    events_seeder.seed
  end
end
