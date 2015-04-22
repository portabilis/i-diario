class Content < ActiveRecord::Base
  acts_as_copy_target

  audited
  has_associated_audits

  include Audit

  belongs_to :unity
  belongs_to :classroom
  belongs_to :discipline
  belongs_to :school_calendar

  validates :unity, :classroom, :discipline, :school_calendar, :content_date, :class_number, :description, presence: true
  validates :class_number, uniqueness: {scope: [:classroom, :discipline, :content_date]}
  validate :is_school_day?

  scope :ordered, -> { order(arel_table[:content_date]) }

  def to_s
    description
  end

  private

  def is_school_day?
    return unless school_calendar && content_date

    errors.add(:content_date, :must_be_school_day) if !school_calendar.school_day? content_date
  end
end
