class DailyFrequencyStudent < ActiveRecord::Base
  include Discardable

  acts_as_copy_target

  audited associated_with: :daily_frequency, except: [:daily_frequency_id, :active]

  attr_accessor :dependence

  before_save :nullify_presence_for_inactive_students

  before_save :default_type_of_teaching

  after_save :update_student_enrollment_classroom

  belongs_to :daily_frequency, inverse_of: :students
  belongs_to :student

  delegate :frequency_date, :class_number, :classroom_id, to: :daily_frequency

  validates :student, :daily_frequency, presence: true

  default_scope -> { kept }

  scope :absences, -> { where("COALESCE(daily_frequency_students.present, 'f') = 'f' ")}
  scope :presents, -> { where("daily_frequency_students.present = 't' ")}
  scope :active, -> { where(active: true) }
  scope :by_daily_frequency_id, ->(daily_frequency_id) { where(daily_frequency_id: daily_frequency_id) }
  scope :by_classroom_id, lambda { |classroom_id| joins(:daily_frequency).merge(DailyFrequency.by_classroom_id(classroom_id)) }
  scope :by_discipline_id, lambda { |discipline_id| joins(:daily_frequency).merge(DailyFrequency.by_discipline_id(discipline_id)) }
  scope :by_student_id, lambda { |student_id| where(student_id: student_id) }
  scope :by_absence_justification_student_id, lambda { |absence_justification_student_id| where(absence_justification_student_id: absence_justification_student_id) }
  scope :by_not_justified, lambda { where(absence_justification_student_id: nil) }
  scope :by_frequency_date, lambda { |frequency_date| joins(:daily_frequency).merge(DailyFrequency.by_frequency_date(frequency_date)) }
  scope :by_period, lambda { |period| joins(:daily_frequency).merge(DailyFrequency.by_period(period)) }
  scope :by_frequency_date_between, lambda { |start_at, end_at| joins(:daily_frequency).merge(DailyFrequency.by_frequency_date_between(start_at, end_at)) }
  scope :by_class_number, lambda { |class_number| joins(:daily_frequency).merge(DailyFrequency.by_class_number(class_number)) }
  scope :by_not_poster, ->(poster_sent) { where("daily_frequency_students.updated_at > ?", poster_sent) }
  scope :general_by_classroom_student_date_between,
        lambda { |classroom_id, student_id, start_at, end_at| where(
                                                       'daily_frequencies.classroom_id' => classroom_id,
                                                       student_id: student_id,
                                                       'daily_frequencies.frequency_date' => start_at.to_date..end_at.to_date,
                                                       'daily_frequencies.discipline_id' => nil)
                                                          .includes(:daily_frequency) }
  scope :general_by_classroom_discipline_student_date_between,
        lambda { |classroom_id, discipline_id, student_id, start_at, end_at| where(
                                                       'daily_frequencies.classroom_id' => classroom_id,
                                                       'daily_frequencies.discipline_id' => discipline_id,
                                                       student_id: student_id,
                                                       'daily_frequencies.frequency_date' => start_at.to_date..end_at.to_date)
                                                          .includes(:daily_frequency) }

  def to_s
    if absence_justification_student_id
      'FJ'
    elsif present?
      TermsDictionary.cached_current.try(:presence_identifier_character) || '.'
    else
      'F'
    end
  end

  def sequence
    return super if super.present?

    update_column(:sequence, student_enrollment_sequence)

    super
  end

  def default_type_of_teaching
    self.present = true if type_of_teaching != TypesOfTeaching::PRESENTIAL
  end

  def student_enrollment_classroom
    StudentEnrollmentClassroom.by_classroom(classroom_id)
                              .by_date(frequency_date)
                              .by_student(student_id)
                              .first
  end

  def update_student_enrollment_classroom
    student = student_enrollment_classroom
    return if student.nil?

    student.type_of_teaching = type_of_teaching
    student.save!
  end

  def student_enrollment_sequence
    student_enrollment_classroom.try(:sequence)
  end

  def nullify_presence_for_inactive_students
    self.present = nil if !self.active
  end
end
