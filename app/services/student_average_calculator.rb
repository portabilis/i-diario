class StudentAverageCalculator
  def initialize(student)
    @student = student
  end

  def calculate(classroom, discipline, step)
    result = 0.0

    student_notes_query = StudentNotesQuery.new(student, discipline, classroom, step.start_at, step.end_at)
    @daily_note_students = student_notes_query.daily_note_students
    @recovery_diary_records = student_notes_query.recovery_diary_records

    if daily_note_students.any? || recovery_diary_records.any?
      result = case
      when step.test_setting.sum_calculation_type?
        score_sum
      when step.test_setting.arithmetic_and_sum_calculation_type?
        calculate_average(score_sum, calculate_average(weight_sum, step.test_setting.maximum_score))
      else
        calculate_average(score_sum, avaliation_count)
      end
    end

    ScoreRounder.new(classroom).round(result)
  end

  private

  attr_accessor :student, :daily_note_students, :recovery_diary_records

  def weight_sum
    sum = 0

    daily_note_students.each do |daily_note_student|
      sum += daily_note_student.daily_note.avaliation.weight unless avaliation_exempted?(daily_note_student.daily_note.avaliation)
    end

    recovery_diary_records.each do |recovery_diary_record|
      sum += recovery_diary_record.avaliation.weight unless avaliation_exempted?(recovery_diary_record.avaliation)
    end

    sum
  end

  def score_sum
    sum = 0

    daily_note_students.each { |daily_note_student| sum += daily_note_student.recovered_note || 0 }
    recovery_diary_records.each { |recovery_diary_record| sum += recovery_diary_record.students.find_by_student_id(student.id).try(&:score) || 0 }

    sum
  end

  def calculate_average(sum, count)
    begin
      sum / count
    rescue ZeroDivisionError
      0
    end
  end

  def avaliation_count
    count = 0

    daily_note_students.each do |daily_note_student|
      count += 1 if daily_note_student.recovered_note
    end

    recovery_diary_records.each do |recovery_diary_record|
      count += 1 if recovery_diary_record.students.find_by_student_id(student.id).try(&:score)
    end

    count
  end

  def avaliation_exempted?(avaliation)
    StudentAvaliationExemptionQuery.new(student).is_exempted(avaliation)
  end
end
