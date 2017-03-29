class TeacherWorkDoneChartFetcher

  def initialize(teacher_id, school_calendar_step_id)
    @teacher_id = teacher_id
    @school_calendar_step_id = school_calendar_step_id
  end

  def fetch!
    return unless teacher || school_calendar_step

    teacher_avaliations = Avaliation
                          .by_classroom_id(teacher_classrooms)
                          .by_discipline_id(teacher_disciplines)
                          .by_school_calendar_step(school_calendar_step_id)

    daily_notes_ids = DailyNote.by_avaliation_id(teacher_avaliations).pluck(:id)
    daily_note_students = DailyNoteStudent.where(daily_note_id: daily_notes_ids).reject(&:exempted?)

    nil_notes_count = DailyNoteStudent.where(id: daily_note_students, note: nil).count
    not_nil_notes_count = daily_note_students.count - nil_notes_count

    { nil_notes: nil_notes_count, not_nil_notes: not_nil_notes_count }
  end

  private

  attr_accessor :teacher_id, :school_calendar_step_id

  def teacher
    Teacher.find_by_id(teacher_id)
  end

  def school_calendar_step
    SchoolCalendarStep.find_by_id(school_calendar_step_id)
  end

  def teacher_classrooms
    Classroom.by_teacher_id(teacher)
  end

  def teacher_disciplines
    Discipline.by_teacher_id(teacher)
  end
end