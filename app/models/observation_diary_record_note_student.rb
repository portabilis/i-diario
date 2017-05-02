class ObservationDiaryRecordNoteStudent < ActiveRecord::Base
  include Audit

  acts_as_copy_target
  audited except: [:observation_diary_record_note_id],
          associated_with: :observation_diary_record_note

  belongs_to :observation_diary_record_note
  belongs_to :student

  validates :observation_diary_record_note, presence: true
  validates(
    :student,
    presence: true,
    uniqueness: { scope: :observation_diary_record_note_id }
  )
end
