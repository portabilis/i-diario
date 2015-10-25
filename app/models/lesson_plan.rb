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
  validates :lesson_plan_date, presence: true
  validates :contents, presence: true

  validate :is_school_day?

  private

  def is_school_day?
    return unless school_calendar && lesson_plan_date

    errors.add(:lesson_plan_date, :must_be_school_day) if !school_calendar.school_day?(lesson_plan_date)
  end
end
