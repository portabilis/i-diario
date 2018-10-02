class StudentNotesQuery
  def initialize(student, discipline, classroom, start_at, end_at)
    @student = student
    @discipline = discipline
    @classroom = classroom
    @start_at = start_at.to_date
    @end_at = end_at.to_date
    @joined_at = student_enrollment.joined_at
  end

  def daily_note_students
    DailyNoteStudent.by_student_id(student)
                    .by_discipline_id(discipline)
                    .by_classroom_id(classroom)
                    .by_test_date_between(start_at, end_at)
                    .joins(daily_note: :avaliation)
                    .merge(Avaliation.by_test_date_between(joined_at, end_at))
  end

  def recovery_diary_records
    avaliation_ids = daily_note_students.map { |daily_note_student| daily_note_student.avaliation.id }

    RecoveryDiaryRecord.by_student_id(student)
                       .by_discipline_id(discipline)
                       .by_classroom_id(classroom)
                       .joins(avaliation_recovery_diary_record: :avaliation)
                       .merge(
                         AvaliationRecoveryDiaryRecord.by_test_date_between(start_at, end_at)
                                                      .where.not(avaliation_id: avaliation_ids))
                       .merge(Avaliation.by_test_date_between(joined_at, end_at))
  end

  private

  attr_accessor :student, :discipline, :classroom, :start_at, :end_at, :joined_at

  def student_enrollment
    StudentEnrollmentClassroom.by_student(student)
                              .by_classroom(classroom)
                              .active
                              .first
  end
end
