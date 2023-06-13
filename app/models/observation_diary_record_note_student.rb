class ObservationDiaryRecordNoteStudent < ApplicationRecord
  include Discardable
  include Audit

  acts_as_copy_target
  audited except: [:observation_diary_record_note_id],
          associated_with: :observation_diary_record_note

  belongs_to :observation_diary_record_note, inverse_of: :note_students
  belongs_to :student

  default_scope -> { kept }

  scope :by_student_id, ->(student_id) { where(student_id: student_id) }

  validates :observation_diary_record_note, presence: true
  validates(
    :student,
    presence: true,
    uniqueness: { scope: :observation_diary_record_note_id, conditions: -> { where(discarded_at: nil) } }
  )
end
