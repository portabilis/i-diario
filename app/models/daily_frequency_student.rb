class DailyFrequencyStudent < ActiveRecord::Base
  include Discardable

  acts_as_copy_target

  audited associated_with: :daily_frequency, except: [:daily_frequency_id, :active]

  attr_accessor :dependence

  before_save :nullify_presence_for_inactive_students

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
  scope :by_frequency_date, lambda { |frequency_date| joins(:daily_frequency).merge(DailyFrequency.by_frequency_date(frequency_date)) }
  scope :by_frequency_date_between, lambda { |start_at, end_at| joins(:daily_frequency).merge(DailyFrequency.by_frequency_date_between(start_at, end_at)) }
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
    if present?
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

  def student_enrollment_sequence
    StudentEnrollmentClassroom.by_classroom(classroom_id)
                              .by_date(frequency_date)
                              .by_student(student_id)
                              .first
                              .try(:sequence)
  end

  def nullify_presence_for_inactive_students
    self.present = nil if !self.active
  end
end
