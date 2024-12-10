class ExamRecordReportForm
  include ActiveModel::Model

  attr_accessor :unity_id,
                :classroom_id,
                :discipline_id,
                :school_calendar_step_id,
                :school_calendar_classroom_step_id

  validates :unity_id,      presence: true
  validates :classroom_id,  presence: true
  validates :discipline_id, presence: true
  validates :school_calendar_step_id, presence: true, unless: :school_calendar_classroom_step_id
  validates :school_calendar_classroom_step_id, presence: true, unless: :school_calendar_step_id

  validate :must_have_daily_notes

  def daily_notes
    return if step.blank?

    @daily_notes = DailyNote.by_unity_id(unity_id)
                            .by_classroom_id(classroom_id)
                            .by_discipline_id(discipline_id)
                            .by_test_date_between(step.start_at, step.end_at)
                            .order_by_avaliation_test_date
  end

  def recovery_lowest_notes?
    return if step.blank?

    @recovery_lowest_notes = AvaliationRecoveryLowestNote.by_unity_id(unity_id)
                                                         .by_classroom_id(classroom_id)
                                                         .by_discipline_id(discipline_id)
                                                         .by_step_id(classroom, step.id)
                                                         .exists?
  end

  def lowest_notes
    return if step.blank?

    lowest_notes = {}

    recovery_diary_record_students = RecoveryDiaryRecordStudent.by_student_id(student_ids)
                                                               .joins(:recovery_diary_record)
                                                               .merge(recovery_diary_records)

    recovery_diary_record_students.each do |recovery_diary_record|
      student_data = {recovery_diary_record.student_id => recovery_diary_record.score}
      lowest_notes = lowest_notes.merge(student_data)
    end

    lowest_notes
  end

  def daily_notes_classroom_steps
    return if classroom_step.blank?

    @daily_notes = DailyNote.by_unity_id(unity_id)
                            .by_classroom_id(classroom_id)
                            .by_discipline_id(discipline_id)
                            .by_test_date_between(classroom_step.start_at, classroom_step.end_at)
                            .order_by_avaliation_test_date
  end

  def info_students
    @student_enrollment_classrooms ||= StudentEnrollmentClassroomsRetriever.call(
      classrooms: classroom_id,
      disciplines: discipline_id,
      start_at: classroom_step.try(:start_at) || step.start_at,
      end_at: classroom_step.try(:end_at) || step.end_at,
      score_type: StudentEnrollmentScoreTypeFilters::NUMERIC,
      search_type: :by_date_range,
      include_inactive: false
    )
  end

  def filter_unique_students
    info_students.each_with_object({}) do |student, unique_students|
      student_id = student[:student].id
      unique_students[student_id] ||= student
    end.values
  end

  def student_ids
    info_students.map { |info| info[:student].id }
  end

  def step
    return if school_calendar_step_id.blank?

    @step ||= SchoolCalendarStep.find(school_calendar_step_id)
  end

  def classroom_step
    return if school_calendar_classroom_step_id.blank?

    @step ||=  SchoolCalendarClassroomStep.find(school_calendar_classroom_step_id)
  end

  def complementary_exams
    @complementary_exams ||= ComplementaryExam
      .by_unity_id(unity_id)
      .by_classroom_id(classroom_id)
      .by_discipline_id(discipline_id)
      .by_date_range((classroom_step || step).start_at, (classroom_step || step).end_at)
      .order(recorded_at: :asc)
  end

  def school_term_recoveries
    return [] unless GeneralConfiguration.current.show_school_term_recovery_in_exam_record_report?

    @school_term_recoveries ||= SchoolTermRecoveryDiaryRecord
      .includes(recovery_diary_record: :discipline)
      .by_unity_id(unity_id)
      .by_classroom_id(classroom_id)
      .by_discipline_id(discipline_id)
      .by_recorded_at((classroom_step || step).start_at..(classroom_step || step).end_at)
      .order(recorded_at: :asc)
  end

  private

  def must_have_daily_notes
    return if errors.present?

    notes = daily_notes_classroom_steps || daily_notes

    if notes.count == 0
      errors.add(:daily_notes, :must_have_daily_notes)
    end
  end

  def recovery_diary_records
    RecoveryDiaryRecord.by_discipline_id(discipline_id)
                       .by_classroom_id(classroom_id)
                       .joins(:students, :avaliation_recovery_lowest_note)
                       .merge(AvaliationRecoveryLowestNote.by_step_id(classroom, step.id))
  end

  def classroom
    @classroom ||= Classroom.find(classroom_id)
  end
end
