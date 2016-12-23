class TransferNote < ActiveRecord::Base
  acts_as_copy_target

  audited
  has_associated_audits

  include Audit

  attr_writer :unity_id

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
  validates :transfer_date, presence: true, date: { not_in_future: true }
  validates :student_id, presence: true
  validates :teacher, presence: true
  validate :transfer_date_must_be_in_step, unless: :school_calendar_classroom_step_id
  validate :transfer_date_must_be_in_classroom_step, unless: :school_calendar_step_id
  validate :at_least_one_daily_note_student

  scope :by_classroom_description, lambda { |description| joins(:classroom).where('classrooms.description ILIKE ?', "%#{description}%" ) }
  scope :by_discipline_description, lambda { |description| joins(:discipline).where('disciplines.description ILIKE ?', "%#{description}%" ) }
  scope :by_student_name, lambda { |name| joins(:student).where('students.name ILIKE ?', "%#{name}%" ) }
  scope :by_transfer_date, lambda { |transfer_date| where(transfer_date: transfer_date.to_date ) }
  scope :by_teacher_id, lambda { |teacher_id| where(teacher_id: teacher_id ) }
  scope :by_discipline_id, lambda { |discipline_id| where(discipline_id: discipline_id ) }
  scope :by_classroom_id, lambda { |classroom_id| where(classroom_id: classroom_id ) }
  scope :by_unity_id, lambda { |unity_id| joins(:classroom).where(classrooms: { unity_id: unity_id }) }

  def unity_id
    classroom.try(:unity_id) || @unity_id
  end

  def transfer_date_must_be_in_step
    return unless transfer_date.present? && school_calendar_step.present?
    errors.add(:transfer_date, :must_be_in_step) unless school_calendar_step.school_calendar_step_day?(transfer_date)
  end

  def transfer_date_must_be_in_classroom_step
    return unless transfer_date.present? && school_calendar_classroom_step.present?
    errors.add(:transfer_date, :must_be_in_step) unless school_calendar_classroom_step.school_calendar_step_day?(transfer_date)
  end

  private

  def at_least_one_daily_note_student
    if daily_note_students.reject{|dns| dns.note.blank?}.empty?
      errors.add(:daily_note_students, :at_least_one_daily_note_student)
    end
  end
end
