class SchoolCalendar < ActiveRecord::Base
  acts_as_copy_target

  before_validation :self_assign_to_steps
  after_create :seed_events

  audited
  has_associated_audits

  include Audit
  include Filterable

  belongs_to :unity

  has_many :steps, -> { includes(:school_calendar).ordered },  class_name: 'SchoolCalendarStep',  dependent: :destroy
  has_many :events, class_name: 'SchoolCalendarEvent', dependent: :destroy

  accepts_nested_attributes_for :steps, reject_if: :all_blank, allow_destroy: true

  validates :year, presence: true,
                   uniqueness: { scope: :unity_id }
  validates :number_of_classes, presence: true,
                                numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 10 }

  validate :at_least_one_assigned_step

  validates_associated :steps

  scope :by_year, lambda { |year| where(year: year) }
  scope :by_unity_id, lambda { |unity_id| where(unity_id: unity_id) }
  scope :by_school_day, lambda { |date| by_school_day(date) }
  scope :ordered, -> { joins(:unity).order(year: :desc).order('unities.name') }

  def to_s
    year
  end

  def school_day?(date)
    return false if events.where(event_date: date, event_type: EventTypes::NO_SCHOOL).any?
    return true if events.where(event_date: date, event_type: EventTypes::EXTRA_SCHOOL).any?
    return false if step(date).nil?
    ![0, 6].include? date.wday
  end

  def step(date)
    steps.all.started_after_and_before(date).first
  end

  def posting_step(date)
    steps.all.posting_date_after_and_before(date).first
  end

  def school_term(date)
    puts '****************************************'
    puts date
    puts '****************************************'
    
    school_terms = { 4 => Bimesters, 3 => Trimesters, 2 => Semesters }

    index_of_step = steps.find_index(step(date))

    school_term = school_terms[steps.count]
    school_term.key_for(index_of_step)
  end

  def school_term_day?(school_term, date)
    real_school_term = school_term(date)
    real_school_term.to_sym == school_term.to_sym
  end

  private

  def self.by_school_day(date)
    joins(:steps).where(SchoolCalendarStep.arel_table[:start_at].lteq(date.to_date))
      .where(SchoolCalendarStep.arel_table[:end_at].gteq(date.to_date))
  end

  def at_least_one_assigned_step
    errors.add(:steps, :at_least_one_step) if steps.empty?
  end

  def self_assign_to_steps
    steps.each { |step| step.school_calendar = self }
  end

  def seed_events
    events_seeder = SchoolCalendarEventsSeeder.new(school_calendar: self)
    events_seeder.seed
  end
end
