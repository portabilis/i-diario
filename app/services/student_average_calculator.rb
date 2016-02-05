class StudentAverageCalculator
  def initialize(student)
    @student = student
  end

  def calculate(discipline_id, school_calendar_step_id)
    steps = SchoolCalendarStep.where(id: school_calendar_step_id)
    averages_sum = 0
    steps.each do |step|
      daily_notes = DailyNoteStudent.by_student_id(@student.id)
        .by_discipline_id(discipline_id)
        .by_test_date_between(step.start_at, step.end_at)

      if step.test_setting.presence && step.test_setting.fix_tests?
        averages_sum = averages_sum + score_sum(daily_notes)
      else
        averages_sum = averages_sum + (calculate_average(score_sum(daily_notes), daily_notes.count))
      end
    end
    averages_sum / steps.count
  end

  def score_sum(daily_notes)
    sum = 0
    daily_notes.each do |daily_note|
      sum = sum + daily_note.recovered_note
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
