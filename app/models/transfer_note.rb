class TransferNote < ActiveRecord::Base
  include Audit

  audited except: [:teacher_id]
  has_associated_audits
  acts_as_copy_target

  acts_as_paranoid

  attr_writer :unity_id
  attr_accessor :transfer_date_copy

  belongs_to :classroom
  belongs_to :discipline
  belongs_to :school_calendar_step
  belongs_to :school_calendar_classroom_step
  belongs_to :student
  belongs_to :teacher
  has_many :daily_note_students, dependent: :destroy
  accepts_nested_attributes_for :daily_note_students, reject_if: proc { |attributes| attributes[:note].blank? }

  validates :unity_id,  presence: true
  validates :classroom_id,  presence: true
  validates :discipline_id, presence: true
  validates :school_calendar_step_id, presence: true, unless: :school_calendar_classroom_step_id
  validates :school_calendar_classroom_step_id, presence: true, unless: :school_calendar_step_id
  validates :transfer_date, presence: true, date: { not_in_future: true }, school_calendar_day: true
  validates :student_id, presence: true
  validates :teacher, presence: true
  validate :transfer_date_must_be_in_step, unless: :school_calendar_classroom_step_id
  validate :transfer_date_must_be_in_classroom_step, unless: :school_calendar_step_id
  validate :at_least_one_daily_note_student, :transfer_date_valid

  scope :by_classroom_description, lambda { |description| joins(:classroom).where('unaccent(classrooms.description) ILIKE unaccent(?)', "%#{description}%" ) }
  scope :by_discipline_description, lambda { |description| joins(:discipline).where('unaccent(disciplines.description) ILIKE unaccent(?)', "%#{description}%" ) }
  scope :by_student_name, lambda { |name| joins(:student).where('unaccent(students.name) ILIKE unaccent(?)', "%#{name}%" ) }
  scope :by_transfer_date, lambda { |transfer_date| where(transfer_date: transfer_date.to_date ) }
  scope :by_teacher_id, lambda { |teacher_id| where(teacher_id: teacher_id ) }
  scope :by_discipline_id, lambda { |discipline_id| where(discipline_id: discipline_id ) }
  scope :by_classroom_id, lambda { |classroom_id| where(classroom_id: classroom_id ) }
  scope :by_unity_id, lambda { |unity_id| joins(:classroom).where(classrooms: { unity_id: unity_id }) }

  delegate :unity, :unity_id, to: :classroom, allow_nil: true

  def transfer_date_must_be_in_step
    return unless transfer_date.present? && school_calendar_step.present?
    errors.add(:transfer_date, :must_be_in_step) unless school_calendar_step.school_calendar_step_day?(transfer_date)
  end

  def transfer_date_must_be_in_classroom_step
    return unless transfer_date.present? && school_calendar_classroom_step.present?
    errors.add(:transfer_date, :must_be_in_step) unless school_calendar_classroom_step.school_calendar_step_day?(transfer_date)
  end

  def school_calendar
    CurrentSchoolCalendarFetcher.new(unity, classroom).fetch
  end

  def recorded_at
    transfer_date
  end

  private

  def at_least_one_daily_note_student
    if daily_note_students.reject{|dns| dns.note.blank?}.empty?
      errors.add(:daily_note_students, :at_least_one_daily_note_student)
    end
  end

  # necessario pois quando inserida uma data invalida, o controller considera
  # o valor de transfer_date como nil e a mensagem mostrada é a de que não pode
  # ficar em branco, quando deve mostrar a de que foi inserida uma data invalida
  def transfer_date_valid
    return if transfer_date_copy.nil?
    begin
      transfer_date_copy.to_date
    rescue ArgumentError
      errors[:transfer_date].clear
      errors.add(:transfer_date, "deve ser uma data válida")
    end
  end
end
