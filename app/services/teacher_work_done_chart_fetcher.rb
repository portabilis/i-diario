class TeacherWorkDoneChartFetcher

  def initialize(params)
    @classroom = params.fetch(:classroom)
    @discipline = params.fetch(:discipline)
    @school_calendar_step = params.fetch(:school_calendar_step)
  end

  def fetch!
    teacher_avaliations = Avaliation
                          .by_classroom_id(classroom)
                          .by_discipline_id(discipline)
                          .by_school_calendar_step(school_calendar_step)

    daily_notes_ids = DailyNote.by_avaliation_id(teacher_avaliations).pluck(:id)
    completed_daily_note_students = DailyNoteStudent
                                    .where(daily_note_id: daily_notes_ids,
                                           active: true)
                                    .where.not(note: nil)
                                    .reject(&:exempted?)

    all_daily_note_students = DailyNoteStudent
                              .where(daily_note_id: daily_notes_ids, active: true)
                              .reject(&:exempted?)

    completed_daily_note_students_count = completed_daily_note_students.count
    all_daily_note_students_count = all_daily_note_students.count

    pending_notes_count = all_daily_note_students_count - completed_daily_note_students_count

    { pending_notes_count: pending_notes_count, completed_notes_count: completed_daily_note_students_count }
  end

  private

  attr_accessor :teacher, :classroom, :discipline, :school_calendar_step

end