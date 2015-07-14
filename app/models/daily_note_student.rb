class DailyNoteStudent < ActiveRecord::Base
  acts_as_copy_target

  audited associated_with: :daily_note, except: :daily_note_id

  belongs_to :daily_note
  belongs_to :student

  validates :student,    presence: true
  validates :daily_note, presence: true
  validates :note, numericality: { greater_than_or_equal_to: 0,
                                   less_than_or_equal_to: proc { |o| o.daily_note.avaliation.school_calendar.maximum_score } }, allow_blank: true
end