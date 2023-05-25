class TransferNote < ApplicationRecord
  include Audit
  include Stepable
  include ColumnsLockable
  include TeacherRelationable
  include Discardable

  not_updatable only: [:classroom_id, :discipline_id]
  teacher_relation_columns only: [:classroom, :discipline]

  audited except: [:recorded_at]
  has_associated_audits

  acts_as_copy_target

  attr_writer :unity_id

  before_destroy :valid_for_destruction?
  before_destroy :before_destroy

  belongs_to :classroom
  belongs_to :discipline
  belongs_to :student
  belongs_to :teacher

  has_many :daily_note_students

  accepts_nested_attributes_for :daily_note_students, reject_if: proc { |attributes| attributes[:note].blank? }

  before_validation :set_transfer_date, on: [:create, :update]

  validates :unity_id, :discipline_id, :student_id, :teacher, presence: true

  default_scope -> { kept }

  scope :by_classroom_description, lambda { |description|
    joins(:classroom).where('unaccent(classrooms.description) ILIKE unaccent(?)', "%#{description}%")
  }
  scope :by_discipline_description, lambda { |description|
    joins(:discipline).merge(Discipline.by_description(description))
  }
  scope :by_student_name, lambda { |student_name|
    joins(:student).where(
      "(unaccent(students.name) ILIKE unaccent(:student_name) or
        unaccent(students.social_name) ILIKE unaccent(:student_name))",
      student_name: "%#{student_name}%"
    )
  }
  scope :by_transfer_date, lambda { |transfer_date| where(transfer_date: transfer_date.to_date) }
  scope :by_teacher_id, lambda { |teacher_id| where(teacher_id: teacher_id) }
  scope :by_discipline_id, lambda { |discipline_id| where(discipline_id: discipline_id) }
  scope :by_classroom_id, lambda { |classroom_id| where(classroom_id: classroom_id) }
  scope :by_unity_id, lambda { |unity_id| joins(:classroom).where(classrooms: { unity_id: unity_id }) }
  scope :by_transfer_date_between, lambda { |start_at, end_at|
    where(transfer_date: start_at.to_date..end_at.to_date)
  }

  delegate :unity, :unity_id, to: :classroom, allow_nil: true

  def ignore_date_validates
    !(new_record? || recorded_at != recorded_at_was)
  end

  private

  def set_transfer_date
    self.transfer_date = recorded_at
  end

  def valid_for_destruction?
    @valid_for_destruction if defined?(@valid_for_destruction)
    @valid_for_destruction = begin
      self.validation_type = :destroy
      forbidden_error = I18n.t('errors.messages.not_allowed_to_post_in_date')

      return false if errors[:transfer_date].include?(forbidden_error)

      self.valid?
    end
  end

  def before_destroy
    TransferNotes.new(self).destroy
  end
end
