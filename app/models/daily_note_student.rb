class DailyNoteStudent < ActiveRecord::Base
  acts_as_copy_target

  audited associated_with: :daily_note, except: :daily_note_id

  belongs_to :daily_note
  belongs_to :student

  validates :student, :daily_note, presence: true
  validates :note, numericality: {greater_than_or_equal_to: 1, less_than_or_equal_to: 10}, if: proc {|o| o.note.present? }
end
