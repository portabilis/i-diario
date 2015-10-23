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

      if step.test_setting.fix_tests?
        averages_sum = averages_sum + daily_notes.sum(:note)
      else
        averages_sum = averages_sum + (daily_notes.sum(:note) / daily_notes.count)
      end
    end
    averages_sum / steps.count
  end
end
