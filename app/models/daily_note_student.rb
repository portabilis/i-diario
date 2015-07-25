class DailyNoteStudent < ActiveRecord::Base
  acts_as_copy_target

  audited associated_with: :daily_note, except: :daily_note_id

  belongs_to :daily_note
  belongs_to :student

  validates :student,    presence: true
  validates :daily_note, presence: true
  validates :note, numericality: { greater_than_or_equal_to: 0,
                                   less_than_or_equal_to: proc { |o| o.daily_note.avaliation.test_setting.maximum_score } }, allow_blank: true


  # Workaround for the error described in issue 177 (https://github.com/portabilis/novo-educacao/issues/177)
  def note=(note)
    # Delocates the value
    note.gsub!(/[.,]/, '.' => '', ',' => '.') if note.kind_of?(String)

    write_attribute(:note, note)
  end
end