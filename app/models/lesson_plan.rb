class LessonPlan < ActiveRecord::Base
  include Audit

  acts_as_copy_target

  audited

  belongs_to :school_calendar
  belongs_to :unity
  belongs_to :classroom

  has_one :discipline_lesson_plan
  has_one :knowledge_area_lesson_plan

  validates :school_calendar, presence: true
  validates :unity, presence: true
  validates :classroom, presence: true
  validates :start_at, presence: true
  validates :end_at, presence: true
  validates :contents, presence: true

  validate :crescent_date_range

  private

  def crescent_date_range
    return if start_at.nil? or end_at.nil?
    if start_at > end_at
      errors.add(:start_at)
      errors.add(:end_at)
      errors.add(:base, :crescent_date_range)
    end
  end

end
