class StudentNotesQuery
  def initialize(student, discipline, classroom, start_at, end_at)
    @student = student
    @discipline = discipline
    @classroom = classroom
    @start_at = start_at.to_date
    @end_at = end_at.to_date
  end

  def daily_note_students
    intersect_dates

    DailyNoteStudent.by_student_id(student)
                    .by_discipline_id(discipline)
                    .by_classroom_id(classroom)
                    .by_test_date_between(start_at, end_at)
                    .includes(
                      daily_note: [
                        avaliation: [
                          :recovery_diary_record,
                          :test_setting_test,
                          :discipline,
                          :school_calendar
                        ]
                      ]
                    )
  end

  def recovery_diary_records
    avaliation_ids = daily_note_students.map { |daily_note_student| daily_note_student.avaliation.id }
    intersect_dates

    RecoveryDiaryRecord.by_student_id(student)
                       .by_discipline_id(discipline)
                       .by_classroom_id(classroom)
                       .joins(:avaliation_recovery_diary_record, :students)
                       .merge(
                         AvaliationRecoveryDiaryRecord.by_test_date_between(
                           start_at,
                           end_at
                         ).where.not(
                           avaliation_id: avaliation_ids
                         )
                       ).where.not(
                         recovery_diary_record_students: {
                           score: nil
                         }
                       )
  end

  private

  attr_accessor :student, :discipline, :classroom, :start_at, :end_at

  def student_joined_at
    joined_at = StudentEnrollmentClassroom.by_student(student)
                                          .by_classroom(classroom)
                                          .active
                                          .first
                                          .joined_at

    Date.parse(joined_at)
  end

  def student_left_at
    left_at = StudentEnrollmentClassroom.by_student(student)
                                        .by_classroom(classroom)
                                        .active
                                        .first
                                        .left_at
    return @end_at if left_at.blank?

    Date.parse(left_at)
  end

  def intersect_dates
    step_range = @start_at..@end_at
    enrollment_range = student_joined_at..student_left_at

    intersection = step_range.to_a & enrollment_range.to_a

    @start_at, @end_at = intersection.minmax unless intersection.empty?
  end
end
