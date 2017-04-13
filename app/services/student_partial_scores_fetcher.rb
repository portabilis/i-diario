class StudentPartialScoresFetcher
  def initialize(student_id, school_calendar_step_id, classroom_id)
    @student_id = student_id
    @school_calendar_step_id = school_calendar_step_id
    @classroom_id = classroom_id
  end

  def fetch!
    classroom = Classroom.find(classroom_id)
    avaliations = Avaliation.by_classroom_id(classroom_id)
                            .by_school_calendar_step(school_calendar_step_id)
                            .ordered

    response = []

    avaliations.each do |avaliation|

      score = DailyNoteStudent.by_student_id(student_id)
                              .by_avaliation(avaliation.id)
                              .first
                              .try(:recovered_note)

      response << {
        description: "#{avaliation}",
        date: I18n.l(avaliation.test_date, format: :week_day),
        discipline: "#{avaliation.discipline}",
        weight: MaximumScoreFetcher.new(avaliation).maximum_score,
        score: score
      }
    end
    response
  end

  private

  attr_accessor :student_id, :school_calendar_step_id, :classroom_id
end
