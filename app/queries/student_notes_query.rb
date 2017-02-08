class StudentNotesQuery
  def initialize(student, discipline, classroom, start_at, end_at)
    @student = student
    @discipline = discipline
    @classroom = classroom
    @start_at = start_at.to_date
    @end_at = end_at.to_date
  end

  def daily_note_students
    relation = DailyNoteStudent.by_student_id(student)
      .by_discipline_id(discipline)
      .by_classroom_id(classroom)
      .by_test_date_between(start_at, end_at)
      .active

    relation
  end

  private

  attr_accessor :student, :discipline, :classroom, :start_at, :end_at
end
