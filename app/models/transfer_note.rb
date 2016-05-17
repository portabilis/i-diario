class TransferNote < ActiveRecord::Base
  acts_as_copy_target

  audited
  has_associated_audits

  include Audit

  attr_writer :unity_id

  belongs_to :classroom
  belongs_to :discipline
  belongs_to :school_calendar_step
  belongs_to :student
  belongs_to :user
  has_many :daily_note_students, dependent: :destroy
  accepts_nested_attributes_for :daily_note_students

  validates :classroom,  presence: true
  validates :discipline, presence: true
  validates :school_calendar_step, presence: true
  validates :transfer_date, presence: true, date: { not_in_future: true }
  validates :student, presence: true
  validates :user, presence: true
  validate :transfer_date_must_be_in_step

  scope :by_classroom_description, lambda { |description| joins(:classroom).where('classrooms.description ILIKE ?', "%#{description}%" ) }
  scope :by_discipline_description, lambda { |description| joins(:discipline).where('disciplines.description ILIKE ?', "%#{description}%" ) }
  scope :by_student_name, lambda { |name| joins(:student).where('students.name ILIKE ?', "%#{name}%" ) }
  scope :by_transfer_date, lambda { |transfer_date| where(transfer_date: transfer_date.to_date ) }
  scope :by_user_id, lambda { |user_id| where(user_id: user_id ) }

  def unity_id
    classroom.try(:unity_id) || @unity_id
  end

  def transfer_date_must_be_in_step
    return unless transfer_date.present? && school_calendar_step.present?
    errors.add(:transfer_date, :must_be_in_step) unless school_calendar_step.school_calendar_step_day?(transfer_date)
  end
end
