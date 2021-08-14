class TeacherWorkDoneChartFetcher

  def initialize(params)
    @classroom = params.fetch(:classroom)
    @discipline = params.fetch(:discipline)
    @school_calendar_step = params.fetch(:school_calendar_step)
  end

  def fetch!
    return { pending_notes_count: 0, completed_notes_count: 0 } if classroom.blank? || discipline.blank?

    teacher_avaliations = Avaliation.by_classroom_id(classroom)
                                    .by_discipline_id(discipline)

    if classroom.calendar
      teacher_avaliations = teacher_avaliations.by_school_calendar_classroom_step(school_calendar_step)
    else
      teacher_avaliations = teacher_avaliations.by_school_calendar_step(school_calendar_step)
    end

    completed_daily_note_students_count = 0
    all_daily_note_students_count = 0

    teacher_avaliations.each do |avaliation|
      students = StudentEnrollmentsList.new(
        classroom: classroom,
        discipline: discipline,
        date: avaliation.test_date,
        show_inactive: false,
        score_type: StudentEnrollmentScoreTypeFilters::NUMERIC,
        search_type: :by_date
      ).student_enrollments
      all_daily_note_students_count += students.count
      all_daily_note_students_count -= AvaliationExemption.by_avaliation(avaliation.id).count

      completed_daily_note_students = DailyNoteStudent.by_avaliation(avaliation.id)
                                                      .by_student_id(students.map(&:student_id))
                                                      .where(active: true)
                                                      .where.not(note: nil)
                                                      .reject(&:exempted?)
      completed_daily_note_students_count += completed_daily_note_students.count
    end

    pending_notes_count = all_daily_note_students_count - completed_daily_note_students_count

    {
      pending_notes_count: pending_notes_count,
      completed_notes_count: completed_daily_note_students_count
    }
  end

  private

  attr_accessor :teacher, :classroom, :discipline, :school_calendar_step

end
