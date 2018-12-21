class StudentNotesQuery
  def initialize(student, discipline, classroom, step_start_at, step_end_at)
    @student = student
    @discipline = discipline
    @classroom = classroom
    @step_start_at = step_start_at.to_date
    @step_end_at = step_end_at.to_date
  end

  def daily_note_students
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

  def transfer_notes
    DailyNoteStudent.by_student_id(student)
                    .by_discipline_id(discipline)
                    .by_classroom_id(classroom)
                    .joins(:transfer_note)
                    .merge(
                      TransferNote.by_transfer_date_between(
                        start_at,
                        end_at
                      )
                    ).where.not(
                      transfer_note: nil
                    )
  end

  private

  attr_accessor :student, :discipline, :classroom, :step_start_at, :step_end_at

  def start_at
    joined_at = StudentEnrollmentClassroom.by_student(student)
                                          .by_classroom(classroom)
                                          .active
                                          .ordered
                                          .last
                                          .joined_at
    return @step_start_at if joined_at.blank? || Date.parse(joined_at) < @step_start_at

    Date.parse(joined_at)
  end

  def end_at
    left_at = StudentEnrollmentClassroom.by_student(student)
                                        .by_classroom(classroom)
                                        .active
                                        .ordered
                                        .last
                                        .left_at
    return @step_end_at if left_at.blank? || Date.parse(left_at) > @step_end_at

    Date.parse(left_at)
  end
end
