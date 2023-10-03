class StudentNotesQuery
  def initialize(student, discipline, classroom, step_start_at, step_end_at)
    @student = student
    @discipline = discipline
    @classroom = classroom
    @step_start_at = step_start_at.to_date
    @step_end_at = step_end_at.to_date
  end

  def daily_note_students_query(student, discipline, classroom, start_date, end_date)
    DailyNoteStudent.by_student_id(student)
                    .by_discipline_id(discipline)
                    .by_classroom_id(classroom)
                    .by_test_date_between(start_date, end_date)
                    .includes(
                      daily_note: [
                        avaliation: [
                          :recovery_diary_record,
                          :test_setting_test,
                          :discipline,
                          :school_calendar
                        ]
                      ]
                    ).where.not(note: nil)
  end

  def daily_note_students
    daily_note_students_query(
      student,
      discipline,
      classroom,
      start_at(student_enrollment_classroom),
      end_at(student_enrollment_classroom)
    ).where(
      transfer_note: nil
    )
  end

  def previous_enrollments_daily_note_students
    daily_notes = []

    previous_enrollments.each do |enrollment|
      daily_notes.concat(
        daily_note_students_query(
          student,
          discipline,
          classroom,
          start_at(enrollment),
          end_at(enrollment)
        ).where(
          transfer_note_id: nil
        )
      )
    end

    daily_notes
  end

  def recovery_diary_records
    RecoveryDiaryRecord.by_student_id(student)
                       .by_discipline_id(discipline)
                       .by_classroom_id(classroom)
                       .joins(:students, avaliation_recovery_diary_record: [:avaliation])
                       .merge(
                         AvaliationRecoveryDiaryRecord.by_test_date_between(
                           @step_start_at, @step_end_at
                         )
                       ).where.not(recovery_diary_record_students: { score: nil })
  end

  def transfer_notes
    DailyNoteStudent.by_student_id(student)
                    .by_discipline_id(discipline)
                    .by_classroom_id(classroom)
                    .joins(:transfer_note)
                    .merge(
                      TransferNote.by_transfer_date_between(
                        step_start_at,
                        step_end_at
                      )
                    ).where.not(transfer_note: nil)
  end

  def recovery_lowest_note_in_step(step)
    RecoveryDiaryRecordStudent.by_student_id(student.id)
                              .joins(:recovery_diary_record)
                              .merge(
                                RecoveryDiaryRecord.by_discipline_id(discipline)
                                                   .by_classroom_id(classroom)
                                                   .joins(:students, :avaliation_recovery_lowest_note)
                                                   .merge(
                                                     AvaliationRecoveryLowestNote.by_step_id(classroom, step.id)
                                                   )
                              ).first
  end

  private

  attr_accessor :student, :discipline, :classroom, :step_start_at, :step_end_at

  def start_at(student_enrollment_classroom)
    joined_at = student_enrollment_classroom.try(:joined_at)

    return step_start_at if joined_at.blank? || Date.parse(joined_at) < step_start_at

    Date.parse(joined_at)
  end

  def end_at(student_enrollment_classroom)
    left_at = student_enrollment_classroom.try(:left_at)

    return step_end_at if left_at.blank? || Date.parse(left_at) > step_end_at

    Date.parse(left_at)
  end

  def student_enrollment_classroom_fetcher
    @student_enrollment_classroom_fetcher ||= StudentEnrollmentClassroomFetcher.new(
      student, classroom, step_start_at, step_end_at
    )
  end

  def student_enrollment_classroom
    @student_enrollment_classroom ||= student_enrollment_classroom_fetcher.current_enrollment
  end

  def previous_enrollments
    @previous_enrollments ||= student_enrollment_classroom_fetcher.previous_enrollments
  end
end
