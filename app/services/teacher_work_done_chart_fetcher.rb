class TeacherWorkDoneChartFetcher

  def initialize(params)
    @classroom = params.fetch(:classroom)
    @discipline = params.fetch(:discipline)
    @school_calendar_step = params.fetch(:school_calendar_step)
  end

  def fetch!
    return { pending_notes_count: 0, completed_notes_count: 0 } if classroom.blank? || discipline.blank?

    teacher_avaliations = Avaliation.includes(daily_notes: :students)
                                    .by_classroom_id(classroom)
                                    .by_discipline_id(discipline)

    if classroom.calendar
      teacher_avaliations = teacher_avaliations.by_school_calendar_classroom_step(school_calendar_step)
    else
      teacher_avaliations = teacher_avaliations.by_school_calendar_step(school_calendar_step)
    end

    all_daily_notes = teacher_avaliations.flat_map(&:daily_notes)
    completed_daily_note_count = all_daily_notes.count do |daily_note|
      daily_note.status == DailyNoteStatuses::COMPLETE
    end

    pending_notes_count = all_daily_notes.size - completed_daily_note_count

    {
      pending_notes_count: pending_notes_count,
      completed_notes_count: completed_daily_note_count
    }
  end

  private

  attr_accessor :teacher, :classroom, :discipline, :school_calendar_step
end
