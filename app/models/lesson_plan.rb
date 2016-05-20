class LessonPlan < ActiveRecord::Base
  include Audit

  acts_as_copy_target

  attr_writer :contents_tags

  audited

  belongs_to :school_calendar
  belongs_to :unity
  belongs_to :classroom

  has_one :discipline_lesson_plan
  has_one :knowledge_area_lesson_plan
  has_and_belongs_to_many :contents, dependent: :destroy

  validates :school_calendar, presence: true
  validates :unity, presence: true
  validates :classroom, presence: true
  validates :start_at, presence: true
  validates :end_at, presence: true
  validates :contents_tags, presence: true
  validates :contents, presence: true

  validate :crescent_date_range

  def contents_tags
    @contents_tags || ContentTagConverter::contents_to_tags(contents)
  end

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
