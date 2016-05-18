class AvaliationExemption < ActiveRecord::Base
  belongs_to :avaliation
  belongs_to :student

  audited
  has_associated_audits

  include Audit

  validates :avaliation_id, :reason, presence: true
  validates :student_id,
    presence: true,
    uniqueness: { scope: [:avaliation_id] }

  validate :ensure_no_score_for_avaliation

  delegate :unity_id, :discipline_id, :school_calendar_id, :classroom_id, :classroom,
    to: :avaliation, prefix: false, allow_nil: true
  delegate :test_date, to: :avaliation, prefix: true, allow_nil: true

  delegate :grade_id, :grade, to: :classroom, prefix: false, allow_nil: true
  delegate :course_id, to: :grade, prefix: false, allow_nil: true

  def school_calendar_step
    SchoolCalendarStep
      .by_school_calendar_id(school_calendar_id)
      .started_after_and_before(avaliation_test_date).try(:id)
  end

  def ensure_no_score_for_avaliation
    # daily_note_student = DailyNoteStudent
    # .by_student_id(student_id)
    # .by_avaliation(avaliation_id)
    # .first
    #
    # if daily_note_student
    #   errors.add(:avaliation, :has_score_on_avaliation) unless daily_note_student.note.nil?
    # end
  end
end
