class ObservationDiaryRecordNote < ApplicationRecord
  include Discardable
  include Audit

  acts_as_copy_target
  audited associated_with: [:observation_diary_record],
          except: [:observation_diary_record_id]
  has_associated_audits

  belongs_to :observation_diary_record, inverse_of: :notes
  has_many :note_students,
           class_name: 'ObservationDiaryRecordNoteStudent',
           dependent: :destroy,
           inverse_of: :observation_diary_record_note
  has_many :students, through: :note_students

  default_scope -> { kept }

  scope :by_student_id, -> student_id { joins(:students).where(students: { id: student_id }) }

  validates :observation_diary_record, presence: true
  validates :description, presence: true

  def student_ids
    students.collect(&:id).join(',')
  end
end
