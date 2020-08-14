class DailyFrequency < ActiveRecord::Base
  include Audit
  include TeacherRelationable

  teacher_relation_columns only: [:classroom, :discipline]

  acts_as_copy_target

  audited
  has_associated_audits

  before_destroy do
    if valid_for_destruction?
      Student.unscoped do
        DailyFrequencyStudent.with_discarded
                             .joins(:student)
                             .by_daily_frequency_id(id)
                             .delete_all
      end
    end
  end

  belongs_to :unity
  belongs_to :classroom
  belongs_to :discipline
  belongs_to :school_calendar
  belongs_to :teacher, foreign_key: :owner_teacher_id

  has_enumeration_for :period, with: Periods, skip_validation: true

  has_many :students, lambda {
    joins(:student).order('students.name')
  }, class_name: 'DailyFrequencyStudent', inverse_of: :daily_frequency

  accepts_nested_attributes_for :students, allow_destroy: true

  validates_date :frequency_date
  validates :unity, :classroom, :school_calendar, :period, presence: true
  validates :frequency_date, presence: true, school_calendar_day: true, posting_date: true

  validate :frequency_date_must_be_less_than_or_equal_to_today
  validate :frequency_must_be_global_or_discipline
  validate :ensure_belongs_to_step

  scope :by_unity_classroom_discipline_class_number_and_frequency_date_between,
        lambda { |unity_id, classroom_id, discipline_id, class_number, start_at, end_at = Time.zone.now|
          where(unity_id: unity_id,
                classroom_id: classroom_id,
                discipline_id: discipline_id,
                class_number: class_number,
                frequency_date: start_at.to_date..end_at.to_date).includes(students: :student)
        }

  scope :by_unity_classroom_and_frequency_date_between,
        lambda { |unity_id, classroom_id, start_at, end_at = Time.zone.now|
          where(unity_id: unity_id,
                classroom_id: classroom_id,
                frequency_date: start_at.to_date..end_at.to_date).includes(students: :student)
        }

  scope :by_teacher_id,
        lambda { |teacher_id|
          joins(discipline: :teacher_discipline_classrooms)
            .where(teacher_discipline_classrooms: { teacher_id: teacher_id })
            .uniq
        }

  scope :by_unity_id, lambda { |unity_id| where(unity_id: unity_id) }
  scope :by_classroom_id, lambda { |classroom_id| where(classroom_id: classroom_id) }
  scope :by_period, ->(period) { where(period: period) }
  scope :by_discipline_id, lambda { |discipline_id| where(discipline_id: discipline_id) }
  scope :by_frequency_date, lambda { |frequency_date| where(frequency_date: frequency_date.to_date) }
  scope :by_frequency_date_between, lambda { |start_at, end_at| where(frequency_date: start_at.to_date..end_at.to_date) }
  scope :by_class_number, lambda { |class_number| where(class_number: class_number) }
  scope :by_school_calendar_id, ->(school_calendar_id) { where(school_calendar_id: school_calendar_id) }
  scope :general_frequency, lambda { where(discipline_id: nil, class_number: nil) }
  scope :has_frequency_for_student, lambda{ |student_id| joins(:students).merge(DailyFrequencyStudent.by_student_id(student_id)) }
  scope :order_by_student_name, -> { order('students.name') }
  scope :order_by_frequency_date, -> { order(:frequency_date) }
  scope :order_by_frequency_date_desc, -> { order(frequency_date: :desc) }
  scope :order_by_class_number, -> { order(:class_number) }
  scope :order_by_unity, -> { order(:unity_id) }
  scope :order_by_classroom, -> { order(:classroom_id) }

  attr_accessor :receive_email_confirmation

  def find_by_student(student_id)
    students.find_by_student_id(student_id)
  end

  def build_or_find_by_student student
    students.where(student_id: student.id).first || students.build(student_id: student.id, present: 1)
  end

  def origin=(value)
    return origin if persisted?

    super(value)
  end

  def optional_teacher
    true
  end

  private

  def valid_for_destruction?
    @valid_for_destruction if defined?(@valid_for_destruction)
    @valid_for_destruction = begin
      valid?
      !errors[:frequency_date].include?(I18n.t('errors.messages.not_allowed_to_post_in_date'))
    end
  end

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

  def ensure_belongs_to_step
    return if school_calendar.blank? || frequency_date.blank?

    step = StepsFetcher.new(classroom).step_by_date(frequency_date)
    errors.add(:frequency_date, I18n.t('errors.messages.not_school_calendar_day')) if step.blank?
  end
end
