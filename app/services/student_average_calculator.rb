class StudentAverageCalculator
  def initialize(student)
    @student = student
  end

  def calculate(classroom_id, discipline_id, school_calendar_step_id)
    result = 0.0
    step = step_fetcher(classroom_id, school_calendar_step_id)
    daily_note_students = DailyNoteStudent.by_student_id(@student.id)
      .by_discipline_id(discipline_id)
      .by_classroom_id(classroom_id)
      .by_test_date_between(step.start_at, step.end_at)
      .active

    if step.test_setting.presence && step.test_setting.fix_tests?
      result = score_sum(daily_note_students)
    else
      result = calculate_average(score_sum(daily_note_students), daily_notes_count(daily_note_students))
    end
    #TODO Modificar classe para receber objetos e não ids (Classroom, Discipline, SchoolCalendarStep)
    classroom = Classroom.find(classroom_id)

    ScoreRounder.new(classroom.exam_rule).round(result)
  end

  def score_sum(daily_note_students)
    sum = 0
    daily_note_students.each do |daily_note_student|
      sum += (daily_note_student.recovered_note || 0)
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

  def daily_notes_count(daily_note_students)
    daily_notes_count = 0
    daily_note_students.each do |daily_note_student|
      avaliation_is_exempted = AvaliationExemption
        .by_student(@student.id)
        .by_avaliation(daily_note_student.daily_note.avaliation_id)
        .any?
      daily_notes_count += 1 unless avaliation_is_exempted
    end
    daily_notes_count
  end

  private

  def step_fetcher(classroom_id, step_id)
    classroom = Classroom.find(classroom_id)
    if classroom.calendar
      SchoolCalendarClassroomStep.find(step_id)
    else
      SchoolCalendarStep.find(step_id)
    end
  end
end
