class ObservationDiaryRecord < ApplicationRecord
  include Discardable
  include Audit
  include ColumnsLockable
  include TeacherRelationable

  not_updatable only: [:classroom_id, :discipline_id]
  teacher_relation_columns only: [:classroom, :discipline]

  acts_as_copy_target
  audited
  has_associated_audits

  before_destroy :valid_for_destruction?, prepend: true

  attr_accessor :unity_id

  delegate :unity, to: :classroom, allow_nil: true

  belongs_to :school_calendar
  belongs_to :teacher
  belongs_to :classroom
  belongs_to :discipline
  has_many :notes, class_name: 'ObservationDiaryRecordNote', dependent: :destroy
  has_many :observation_diary_record_attachments, dependent: :destroy
  has_many :students, through: :notes

  accepts_nested_attributes_for :observation_diary_record_attachments, allow_destroy: true
  accepts_nested_attributes_for :notes, allow_destroy: true

  default_scope -> { kept }

  scope :by_unity, -> unity_ids { joins(:classroom).where(classrooms: { unity_id: unity_ids }) }
  scope :by_teacher, -> teacher_ids { where(teacher_id: teacher_ids) }
  scope :by_classroom, -> classroom_ids { where(classroom_id: classroom_ids) }
  scope :by_discipline, -> discipline_ids { where(discipline_id: discipline_ids) }
  scope :by_date, -> date { where(date: date.to_date) }
  scope :by_student_id, -> student_id { joins(:notes).merge(ObservationDiaryRecordNote.by_student_id(student_id)) }
  scope :ordered, -> { order(date: :desc) }

  validates_date :date
  validates :school_calendar, presence: true
  validates :teacher, presence: true
  validates :classroom, presence: true
  validates :discipline, presence: true, on: :create
  validates(
    :date,
    presence: true,
    uniqueness: {
      scope: [:school_calendar_id, :teacher_id, :classroom_id, :discipline_id],
      conditions: -> { where(discarded_at: nil) }
    },
    not_in_future: true,
    school_calendar_day: true,
    posting_date: true
  )
  validates :notes, presence: true
  validates :unity_id, presence: true

  before_validation :self_assign_to_notes

  def unity_id
    classroom.try(:unity_id) || @unity_id
  end

  private

  def self_assign_to_notes
    notes.each { |note| note.observation_diary_record = self }
  end

  def valid_for_destruction?
    @valid_for_destruction if defined?(@valid_for_destruction)
    @valid_for_destruction = begin
      self.validation_type = :destroy
      valid?
      !errors[:date].include?(I18n.t('errors.messages.not_allowed_to_post_in_date'))
    end
  end
end
