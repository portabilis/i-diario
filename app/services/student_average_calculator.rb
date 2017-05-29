class StudentAverageCalculator
  def initialize(student)
    @student = student
  end

  def calculate(classroom, discipline, step)
    result = 0.0

    daily_note_students = StudentNotesQuery.new(@student, discipline, classroom, step.start_at, step.end_at).daily_note_students
    if daily_note_students.any?
      if step.test_setting.sum_calculation_type?
        result = score_sum(daily_note_students)
      elsif step.test_setting.arithmetic_and_sum_calculation_type?
        result = calculate_average(score_sum(daily_note_students), calculate_average(weight_sum(daily_note_students), step.test_setting.maximum_score))
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
      sum += daily_note_student.daily_note.avaliation.weight unless avaliation_exempted?(daily_note_student.daily_note.avaliation)
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
      daily_notes_count += 1 unless avaliation_exempted?(daily_note_student.daily_note.avaliation)
    end
    daily_notes_count
  end

  def avaliation_exempted?(avaliation)
    StudentAvaliationExemptionQuery.new(@student).is_exempted(avaliation)
  end
end
