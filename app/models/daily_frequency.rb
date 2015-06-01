class DailyFrequency < ActiveRecord::Base
  acts_as_copy_target

  audited
  has_associated_audits

  include Audit

  belongs_to :unity
  belongs_to :classroom
  belongs_to :discipline
  belongs_to :school_calendar

  has_many :students, class_name: "DailyFrequencyStudent", dependent: :destroy
  accepts_nested_attributes_for :students

  validates :unity, :classroom, :frequency_date, :school_calendar, presence: true
  validates :global_absence, inclusion: [true, false]
  validates :discipline, presence: true, unless: :global_absence?
  validate  :is_school_day?

  scope :ordered, -> { order(arel_table[:class_number].asc) }

  def build_or_find_by_student student
    students.where(student_id: student.id).first || students.build(student_id: student.id, present: 1)
  end

  private

  def is_school_day?
    return unless school_calendar && frequency_date

    errors.add(:frequency_date, :must_be_school_day) if !school_calendar.school_day? frequency_date
  end
end