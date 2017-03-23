class PartialScoreRecordReportForm
  include ActiveModel::Model

  attr_accessor :unity_id,
                :classroom_id,
                :student_id,
                :school_calendar_step_id,
                :school_calendar_classroom_step_id,
                :school_calendar_year

  validates :unity_id,      presence: true
  validates :classroom_id,  presence: true
  validates :student_id, presence: true
  validates :school_calendar_step_id, presence: true, unless: :school_calendar_classroom_step_id
  validates :school_calendar_classroom_step_id, presence: true, unless: :school_calendar_step_id

  validate :must_have_daily_note_students

  def daily_note_students
    @daily_note_students ||= DailyNoteStudent.includes(:daily_note)
                                             .by_classroom_id(classroom_id)
                                             .by_student_id(student_id)
                                             .by_test_date_between(school_calendar.first_day, school_calendar.last_day)
                                             .order_by_discipline_and_date
  end

  def step
    return unless school_calendar_step_id || school_calendar_classroom_step_id

    if classroom.calendar
      @step ||= SchoolCalendarClassroomStep.find(school_calendar_classroom_step_id)
    else
      @step ||= SchoolCalendarStep.find(school_calendar_step_id)
    end
  end

  def school_calendar
    if classroom.calendar
      step.school_calendar_classroom
    else
      step.school_calendar
    end
  end

  def student
    return unless student_id

    @student ||= Student.find(student_id)
  end

  def classroom
    return unless classroom_id

    @classroom ||= Classroom.find(classroom_id)
  end

  def unity
    return unless unity_id

    @unity ||= Unity.find(unity_id)
  end

  private

  def must_have_daily_note_students
    return unless errors.blank?

    if daily_note_students.count == 0
      errors.add(:daily_note_students, :must_have_daily_note_students)
    end
  end
end
