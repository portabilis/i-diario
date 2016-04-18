class ObservationDiaryRecord < ActiveRecord::Base
  include Audit

  acts_as_copy_target
  audited
  has_associated_audits

  attr_accessor :unity_id

  delegate :unity, to: :classroom, allow_nil: true

  belongs_to :school_calendar
  belongs_to :teacher
  belongs_to :classroom
  belongs_to :discipline
  has_many :notes, class_name: 'ObservationDiaryRecordNote', dependent: :destroy
  accepts_nested_attributes_for :notes, allow_destroy: true

  scope :by_unity, -> unity_ids { joins(:classroom).where(classrooms: { unity_id: unity_ids }) }
  scope :by_teacher, -> teacher_ids { where(teacher_id: teacher_ids) }
  scope :by_classroom, -> classroom_ids { where(classroom_id: classroom_ids) }
  scope :by_discipline, -> discipline_ids { where(discipline_id: discipline_ids) }
  scope :by_date, -> date { where(date: date) }
  scope :ordered, -> { order(date: :desc) }

  validates :school_calendar, presence: true
  validates :teacher, presence: true
  validates :classroom, presence: true
  validates :discipline, presence: true, if: :require_discipline?
  validates :discipline, absence: true, unless: :require_discipline?
  validates(
    :date,
    presence: true,
    uniqueness: { scope: [:school_calendar_id, :teacher_id, :classroom_id, :discipline_id] },
    not_in_future: true,
    school_calendar_day: true
  )
  validates :notes, presence: true

  before_validation :self_assign_to_notes

  def unity_id
    classroom.try(:unity_id) || @unity_id
  end

  private

  def self_assign_to_notes
    notes.each { |note| note.observation_diary_record = self }
  end

  def require_discipline?
    frequency_type_definer = FrequencyTypeDefiner.new(classroom, teacher)
    frequency_type_definer.define!
    frequency_type_definer.frequency_type == FrequencyTypes::BY_DISCIPLINE
  end
end
