class ExamRecordReportForm
  include ActiveModel::Model

  attr_accessor :unity_id,
                :classroom_id,
                :discipline_id,
                :school_calendar_step_id

  validates :unity_id,      presence: true
  validates :classroom_id,  presence: true
  validates :discipline_id, presence: true
  validates :school_calendar_step_id, presence: true

  validate :must_have_daily_notes

  def daily_notes
    DailyNote.by_unity_classroom_discipline_and_avaliation_test_date_between(unity_id,
                                                                             classroom_id,
                                                                             discipline_id,
                                                                             step.start_at,
                                                                             step.end_at).order_by_student_name
                                                                                         .order_by_avaliation_test_date
  end

  def step
    return unless school_calendar_step_id

    SchoolCalendarStep.find(school_calendar_step_id)
  end

  private

  def must_have_daily_notes
    return unless errors.blank?

    if daily_notes.count == 0
      errors.add(:daily_notes, :must_have_daily_notes)
    end
  end
end