class SchoolCalendar < ActiveRecord::Base
  acts_as_copy_target

  after_create :seed_events

  audited
  has_associated_audits

  include Audit

  has_many :steps,  class_name: 'SchoolCalendarStep',  dependent: :destroy
  has_many :events, class_name: 'SchoolCalendarEvent', dependent: :destroy

  accepts_nested_attributes_for :steps, reject_if: :all_blank, allow_destroy: true

  validates :year, presence: true,
                   uniqueness: true
  validates :number_of_classes, presence: true
  validate :at_least_one_assigned_step

  scope :ordered, -> { order(arel_table[:year]) }

  def to_s
    year
  end

  def school_day?(date)
    return false if events.where(event_date: date, event_type: EventTypes::NO_SCHOOL).any?
    return true if events.where(event_date: date, event_type: EventTypes::EXTRA_SCHOOL).any?
    return false if step(date).nil?
    ![0, 6].include? date.wday
  end

  def step date
    steps.all.started_after_and_before(date).first
  end

  private

  def at_least_one_assigned_step
    errors.add(:steps, :at_least_one_step) if steps.empty?
  end

  def seed_events
    events_seeder = SchoolCalendarEventsSeeder.new(school_calendar: self)
    events_seeder.seed
  end
end
