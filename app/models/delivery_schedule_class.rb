class ***REMOVED***Class < ActiveRecord::Base
  acts_as_copy_target
  audited associated_with: :delivery_schedule

  after_initialize :fill_repeat_default

  has_enumeration_for :repeat, with: ***REMOVED***Periodicities

  belongs_to :delivery_schedule
  belongs_to :***REMOVED***_class

  validates :***REMOVED***_class_id, presence: true
  validates :date, presence: true, date: true
  validates :repeat, presence: true

  delegate :start_date, :end_date, to: :delivery_schedule

  scope :by_***REMOVED***_class_id, lambda { |***REMOVED***_class_id| where(***REMOVED***_class_id: ***REMOVED***_class_id) }
  scope :by_date_between, lambda { |start_at, end_at| where(date: start_at.to_date..end_at.to_date) }
  scope :by_unity_id, lambda { |unity_id| joins(:delivery_schedule).merge(***REMOVED***.by_unities(unity_id)) }

  def fill_repeat_default
    self.repeat = 'never' if self.repeat.blank?
  end
end
