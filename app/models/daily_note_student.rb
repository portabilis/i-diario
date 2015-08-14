class DailyNoteStudent < ActiveRecord::Base
  acts_as_copy_target

  audited associated_with: :daily_note, except: :daily_note_id

  belongs_to :daily_note
  belongs_to :student

  validates :student,    presence: true
  validates :daily_note, presence: true
  validates :note, numericality: { greater_than_or_equal_to: 0,
                                   less_than_or_equal_to: proc { |o| o.daily_note.avaliation.test_setting.maximum_score } }, allow_blank: true

  scope :by_classroom_discipline_student_and_avaliation_test_date_between,
        lambda { |classroom_id, discipline_id, student_id, start_at, end_at| where(
                                                       'daily_notes.classroom_id' => classroom_id,
                                                       'daily_notes.discipline_id' => discipline_id,
                                                       student_id: student_id,
                                                       'avaliations.test_date' => start_at.to_date..end_at.to_date)
                                                          .includes(daily_note: [:avaliation]) }


  # Workaround for the error described in issue 177 (https://github.com/portabilis/novo-educacao/issues/177)
  def note=(note)
    # Delocates the value
    note.gsub!(/[.,]/, '.' => '', ',' => '.') if note.kind_of?(String)

    write_attribute(:note, note)
  end
end