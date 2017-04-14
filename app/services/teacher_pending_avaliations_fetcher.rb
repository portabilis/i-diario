class TeacherPendingAvaliationsFetcher

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
                          .by_status(DailyNoteStatuses::INCOMPLETE)

    teacher_avaliations
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