class StudentAverageCalculator
  def initialize(student)
    @student = student
  end

  def calculate(discipline_id, school_calendar_step_id)
    averages_sum = 0
    step = SchoolCalendarStep.find(school_calendar_step_id)
    daily_notes = DailyNoteStudent.by_student_id(@student.id)
      .by_discipline_id(discipline_id)
      .by_test_date_between(step.start_at, step.end_at)

    if step.test_setting.presence && step.test_setting.fix_tests?
      score_sum(daily_notes)
    else
      calculate_average(score_sum(daily_notes), daily_notes.count)
    end
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
