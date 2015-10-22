class StudentAverageCalculator
  def initialize(student)
    @student = student
  end

  def calculate(discipline_id, school_calendar_step_id)
    step = SchoolCalendarStep.find(school_calendar_step_id)
    daily_notes = DailyNoteStudent.by_student_id(@student.id)
      .by_discipline_id(discipline_id)
      .by_test_date_between(step.start_at, step.end_at)

    if step.test_setting.fix_tests?
      daily_notes.sum(:note)
    else
      daily_notes.sum(:note) / daily_notes.count
    end
  end
end
