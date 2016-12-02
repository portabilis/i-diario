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
    @daily_notes = DailyNote
      .by_unity_id(unity_id)
      .by_classroom_id(classroom_id)
      .by_discipline_id(discipline_id)
      .by_test_date_between(step.start_at, step.end_at)
      .order_by_avaliation_test_date
  end

  def students_enrollments
    StudentEnrollmentsList.new(classroom: classroom_id,
                               discipline: discipline_id,
                               start_at: step.start_at,
                               end_at: step.end_at,
                               search_type: :by_date_range)
                          .student_enrollments
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

  def remove_duplicated_enrollments(students_enrollments)
    students_enrollments = students_enrollments.select do |student_enrollment|
      enrollments_for_student = StudentEnrollment
        .by_student(student_enrollment.student_id)
        .by_classroom(classroom_id)

      if enrollments_for_student.count > 1
        enrollments_for_student.last != student_enrollment
      else
        true
      end
    end

    students_enrollments
  end
end
