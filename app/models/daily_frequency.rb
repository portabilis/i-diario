class DailyFrequency < ActiveRecord::Base
  acts_as_copy_target

  audited
  has_associated_audits

  include Audit

  belongs_to :unity
  belongs_to :classroom
  belongs_to :discipline
  belongs_to :school_calendar

  has_many :students, -> { includes(:student).order('students.name') }, class_name: 'DailyFrequencyStudent', dependent: :destroy
  accepts_nested_attributes_for :students

  validates :unity, :classroom, :frequency_date, :school_calendar, presence: true
  validates :global_absence, inclusion: [true, false]
  validates :discipline, presence: true, unless: :global_absence?
  validate  :is_school_day?

  scope :by_unity_classroom_discipline_class_number_and_frequency_date_between,
        lambda { |unity_id, classroom_id, discipline_id, class_number, start_at, end_at| where(unity_id: unity_id,
                                                                                               classroom_id: classroom_id,
                                                                                               discipline_id: discipline_id,
                                                                                               class_number: class_number,
                                                                                               frequency_date: start_at.to_date..end_at.to_date).includes(students: :student) }
  scope :by_unity_classroom_and_frequency_date_between,
        lambda { |unity_id, classroom_id, start_at, end_at| where(unity_id: unity_id,
                                                                  classroom_id: classroom_id,
                                                                  frequency_date: start_at.to_date..end_at.to_date).includes(students: :student) }
  scope :order_by_student_name, -> { order('students.name') }
  scope :order_by_frequency_date, -> { order(:frequency_date) }
  scope :order_by_class_number, -> { order(:class_number) }

  def build_or_find_by_student student
    students.where(student_id: student.id).first || students.build(student_id: student.id, present: 1)
  end

  private

  def is_school_day?
    return unless school_calendar && frequency_date

    errors.add(:frequency_date, :must_be_school_day) if !school_calendar.school_day? frequency_date
  end
end