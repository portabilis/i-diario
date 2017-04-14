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

    student_enrollments_count = 0
    teacher_avaliations.each do |avaliation|
      student_enrollments_count += StudentEnrollmentsList.new(classroom: avaliation.classroom,
                                                           discipline: avaliation.discipline,
                                                           date: avaliation.test_date,
                                                           show_inactive: false).student_enrollments.count
    end

    daily_notes_ids = DailyNote.by_avaliation_id(teacher_avaliations).pluck(:id)
    daily_note_students = DailyNoteStudent.where(daily_note_id: daily_notes_ids, active: true).where.not(note: nil).reject(&:exempted?)

    completed_notes_count = daily_note_students.count

    pending_notes_count = student_enrollments_count - completed_notes_count

    { pending_notes_count: pending_notes_count, completed_notes_count: completed_notes_count }
  end

  private

  attr_accessor :teacher, :classroom, :discipline, :school_calendar_step

end