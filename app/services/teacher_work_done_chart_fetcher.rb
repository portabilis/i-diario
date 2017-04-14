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

    student_enrollments_count = 0
    teacher_avaliations.each do |avaliation|
      student_enrollment_list = StudentEnrollmentsList.new(classroom: avaliation.classroom,
                                                           discipline: avaliation.discipline,
                                                           date: avaliation.test_date,
                                                           show_inactive: false)

      student_enrollments_count += student_enrollment_list.student_enrollments.count
    end

    daily_notes_ids = DailyNote.by_avaliation_id(teacher_avaliations).pluck(:id)
    daily_note_students = DailyNoteStudent.where(daily_note_id: daily_notes_ids, active: true).where.not(note: nil).reject(&:exempted?)

    completed_notes_count = daily_note_students.count

    pending_notes_count = student_enrollments_count - completed_notes_count

    { pending_notes_count: pending_notes_count, completed_notes_count: completed_notes_count }
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