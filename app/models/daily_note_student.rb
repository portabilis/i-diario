class DailyNoteStudent < ActiveRecord::Base
  acts_as_copy_target

  audited associated_with: :daily_note, except: :daily_note_id

  belongs_to :daily_note
  belongs_to :student

  delegate :avaliation, to: :daily_note

  validates :student,    presence: true
  validates :daily_note, presence: true
  validates :note, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: lambda { |daily_note_student| daily_note_student.maximum_score } }, allow_blank: true

  scope :by_classroom_discipline_student_and_avaliation_test_date_between,
        lambda { |classroom_id, discipline_id, student_id, start_at, end_at| where(
                                                       'daily_notes.classroom_id' => classroom_id,
                                                       'daily_notes.discipline_id' => discipline_id,
                                                       student_id: student_id,
                                                       'avaliations.test_date' => start_at.to_date..end_at.to_date)
                                                          .includes(daily_note: [:avaliation]) }

  scope :regular_by_classroom_discipline_student_and_avaliation_test_date_between,
        lambda { |classroom_id, discipline_id, student_id, start_at, end_at| where(
                                                       'daily_notes.classroom_id' => classroom_id,
                                                       'daily_notes.discipline_id' => discipline_id,
                                                       'test_setting_tests.test_type' => TestTypes::REGULAR,
                                                       student_id: student_id,
                                                       'avaliations.test_date' => start_at.to_date..end_at.to_date)
                                                          .includes(daily_note: [avaliation: [:test_setting_test]]) }

  scope :recovery_by_classroom_discipline_student_and_avaliation_test_date_between,
        lambda { |classroom_id, discipline_id, student_id, start_at, end_at| where(
                                                       'daily_notes.classroom_id' => classroom_id,
                                                       'daily_notes.discipline_id' => discipline_id,
                                                       'test_setting_tests.test_type' => TestTypes::RECOVERY,
                                                       student_id: student_id,
                                                       'avaliations.test_date' => start_at.to_date..end_at.to_date)
                                                          .includes(daily_note: [avaliation: [:test_setting_test]]) }

  def maximum_score
    return avaliation.test_setting.maximum_score if !avaliation.test_setting.fix_tests
    return avaliation.weight.to_f if avaliation.test_setting_test.allow_break_up
    return avaliation.test_setting_test.weight if !avaliation.test_setting_test.allow_break_up
  end
end