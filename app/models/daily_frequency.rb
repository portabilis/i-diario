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
  accepts_nested_attributes_for :students, allow_destroy: true

  validates_date :frequency_date
  validates :unity, :classroom, :school_calendar, presence: true
  validates :frequency_date, presence: true, school_calendar_day: true

  validate :frequency_date_must_be_less_than_or_equal_to_today
  validate :frequency_must_be_global_or_discipline

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

  scope :by_unity_id, lambda { |unity_id| where(unity_id: unity_id) }
  scope :by_classroom_id, lambda { |classroom_id| where(classroom_id: classroom_id) }
  scope :by_discipline_id, lambda { |discipline_id| where(discipline_id: discipline_id) }
  scope :by_frequency_date_between, lambda { |start_at, end_at| where(frequency_date: start_at.to_date..end_at.to_date) }
  scope :by_class_number, lambda { |class_number| where(class_number: class_number) }
  scope :general_frequency, lambda { where(discipline_id: nil, class_number: nil) }

  scope :order_by_student_name, -> { order('students.name') }
  scope :order_by_frequency_date, -> { order(:frequency_date) }
  scope :order_by_class_number, -> { order(:class_number) }

  def build_or_find_by_student student
    students.where(student_id: student.id).first || students.build(student_id: student.id, present: 1)
  end

  private

  def frequency_date_must_be_less_than_or_equal_to_today
    return unless frequency_date

    if frequency_date > Time.zone.today
      errors.add(:frequency_date, :must_be_less_than_or_equal_to_today)
    end
  end

  def frequency_must_be_global_or_discipline
    if discipline && !class_number ||
       !discipline && class_number
      errors.add(:base, :frequency_type_must_be_valid)
    end
  end
end
