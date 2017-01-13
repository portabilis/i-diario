class StudentAverageCalculator
  def initialize(student)
    @student = student
  end

  def calculate(classroom, discipline, school_calendar_step)
    result = 0.0

    daily_note_students = StudentNotesQuery.new(@student, discipline, classroom, school_calendar_step.start_at, school_calendar_step.end_at).daily_note_students
    if daily_note_students.any?
      if school_calendar_step.test_setting.sum_calculation_type?
        result = score_sum(daily_note_students)
      elsif school_calendar_step.test_setting.arithmetic_and_sum_calculation_type?
        result = (score_sum(daily_note_students) / (weight_sum(daily_note_students) / school_calendar_step.test_setting.maximum_score))
      else
        result = calculate_average(score_sum(daily_note_students), daily_notes_count(daily_note_students))
      end
    end

    result = ScoreRounder.new(classroom.exam_rule).round(result)
    result
  end

  private

  def weight_sum(daily_note_students)
    sum = 0
    daily_note_students.each do |daily_note_student|
      sum += daily_note_student.daily_note.avaliation.weight
    end
    sum
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
      avaliation_is_exempted = StudentAvaliationExemptionQuery.new(@student).is_exempted(daily_note_student.daily_note.avaliation)
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
