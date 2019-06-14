class TeacherPendingAvaliationsFetcher

  def initialize(params)
    @teacher = params.fetch(:teacher)
    @classroom = params.fetch(:classroom)
    @discipline = params.fetch(:discipline)
    @school_calendar_step = params.fetch(:school_calendar_step)
  end

  def fetch!
    teacher_avaliations = Avaliation
                          .by_classroom_id(classroom)
                          .by_discipline_id(discipline)
                          .by_status(DailyNoteStatuses::INCOMPLETE)

    if classroom.calendar
      teacher_avaliations.by_school_calendar_classroom_step(school_calendar_step)
    else
      teacher_avaliations.by_school_calendar_step(school_calendar_step)
    end
  end

  private

  attr_accessor :teacher, :school_calendar_step, :classroom, :discipline
end