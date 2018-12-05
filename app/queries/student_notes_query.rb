class StudentNotesQuery
  def initialize(student, discipline, classroom, start_at, end_at)
    @student = student
    @discipline = discipline
    @classroom = classroom
    @start_at = start_at.to_date
    @end_at = end_at.to_date
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
                    .where.not(note: nil)
  end

  def recovery_diary_records
    avaliation_ids = daily_note_students.map { |daily_note_student| daily_note_student.avaliation.id }

    RecoveryDiaryRecord.by_student_id(student)
                       .by_discipline_id(discipline)
                       .by_classroom_id(classroom)
                       .joins(:avaliation_recovery_diary_record, :students)
                       .merge(
                         AvaliationRecoveryDiaryRecord.by_test_date_between(start_at, end_at)
                                                      .where.not(avaliation_id: avaliation_ids)
                       )
                       .where.not(recovery_diary_record_students: { score: nil })
  end

  def avaliations_ids_without_note
    nil_daily_notes = DailyNoteStudent.by_student_id(student)
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
                                      .where(note: nil)

    avaliation_ids = nil_daily_notes.map { |daily_note_student| daily_note_student.avaliation.id }

    nil_recovery_notes = RecoveryDiaryRecord.by_student_id(student)
                                            .by_discipline_id(discipline)
                                            .by_classroom_id(classroom)
                                            .joins(:avaliation_recovery_diary_record, :students)
                                            .merge(
                                              AvaliationRecoveryDiaryRecord.by_test_date_between(start_at, end_at)
                                                                           .where(avaliation_id: avaliation_ids)
                                            )
                                            .where(recovery_diary_record_students: { score: nil })

    nil_recovery_notes.map do |recovery_diary_record|
      recovery_diary_record.avaliation_recovery_diary_record.avaliation.id
    end
  end

  private

  attr_accessor :student, :discipline, :classroom, :start_at, :end_at
end
