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
                          .by_school_calendar_step(school_calendar_step)
                          .by_status(DailyNoteStatuses::INCOMPLETE)

    teacher_avaliations
  end

  private

  attr_accessor :teacher, :school_calendar_step, :classroom, :discipline
end