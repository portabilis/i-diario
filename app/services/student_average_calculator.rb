class StudentAverageCalculator
  def initialize(student)
    @student = student
  end

  def calculate(classroom_id, discipline_id, school_calendar_step_id)
    result = 0.0
    step = SchoolCalendarStep.find(school_calendar_step_id)
    daily_notes = DailyNoteStudent.by_student_id(@student.id)
      .by_discipline_id(discipline_id)
      .by_classroom_id(classroom_id)
      .by_test_date_between(step.start_at, step.end_at)

    if step.test_setting.presence && step.test_setting.fix_tests?
      result = score_sum(daily_notes)
    else
      result = calculate_average(score_sum(daily_notes), daily_notes.count)
    end
    #TODO Modificar classe para receber objetos e não ids (Classroom, Discipline, SchoolCalendarStep)
    classroom = Classroom.find(classroom_id)

    ScoreRounder.new(classroom.exam_rule).round(result)
  end

  def score_sum(daily_notes)
    sum = 0
    daily_notes.each do |daily_note|
      sum += (daily_note.recovered_note || 0)
    end
    sum
  end

  def calculate_average(sum, count)
    begin
      sum / count
    rescue ZeroDivisionError
      0
    end
  end
end
