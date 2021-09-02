class StudentAverageCalculator
  def initialize(student)
    @student = student
  end

  def calculate(classroom, discipline, step)
    student_notes_query = StudentNotesQuery.new(student, discipline, classroom, step.start_at, step.end_at)
    @daily_note_students = student_notes_query.daily_note_students + student_notes_query.transfer_notes +
                           student_notes_query.previous_enrollments_daily_note_students
    test_setting = test_setting(classroom, step)

    @recovery_diary_records = student_notes_query.recovery_diary_records

    return if daily_note_students.blank? && recovery_diary_records.blank?

    result = calculate_average_by_settings(test_setting)

    return if result.blank?

    result = ComplementaryExamCalculator.new(
      [AffectedScoreTypes::STEP_AVERAGE, AffectedScoreTypes::BOTH],
      student.id,
      discipline.id,
      classroom.id,
      step
    ).calculate(result)

    ScoreRounder.new(classroom, RoundedAvaliations::NUMERICAL_EXAM).round(result)
  end

  private

  attr_accessor :student, :daily_note_students, :recovery_diary_records

  def weight_sum
    weights = []

    daily_note_students.each do |daily_note_student|
      next if avaliation_exempted?(daily_note_student.daily_note.avaliation)

      weights << daily_note_student.daily_note.avaliation.weight
    end

    recovery_diary_records.each do |recovery_diary_record|
      next if avaliation_exempted?(recovery_diary_record.avaliation_recovery_diary_record.avaliation)

      weights << recovery_diary_record.avaliation_recovery_diary_record.avaliation.weight
    end

    weights.reduce(:+)
  end

  def score_sum
    avaliations = []
    @scores = []

    daily_note_students.each do |daily_note_student|
      next if avaliation_exempted?(daily_note_student.daily_note.avaliation)

      avaliations << { note: daily_note_student.recovered_note, avaliation_id: daily_note_student.daily_note.avaliation.id }
    end

    recovery_diary_records.each do |recovery_diary_record|
      next if avaliation_exempted?(recovery_diary_record.avaliation_recovery_diary_record.avaliation)
      next unless (score = recovery_diary_record.students.find_by(student_id: student.id)&.score)

      avaliations << { note: score, avaliation_id: recovery_diary_record.avaliation_recovery_diary_record.avaliation.id }
    end

    extract_note_avaliation(avaliations)

    @scores.reduce(:+)
  end

  def extract_note_avaliation(avaliations)
    avaliations.uniq.group_by { |k, v| k[:avaliation_id] }.each do |avaliation|
      note = 0
      if avaliation.last.count > 1
        avaliation.last.each { |array| note = array[:note] if note < array[:note] }
      else
        note = avaliation.last.last[:note]
      end
      @scores << note
    end
  end

  def calculate_average(sum, count)
    count == 0 ? 0 : sum / count
  end

  def avaliation_exempted?(avaliation)
    StudentAvaliationExemptionQuery.new(student).is_exempted(avaliation)
  end

  def test_setting(classroom, step)
    TestSettingFetcher.current(classroom, step)
  end

  def calculate_average_by_settings(test_setting)
    return if score_sum.blank?

    if test_setting.sum_calculation_type?
      score_sum / test_setting.default_division_weight
    elsif test_setting.arithmetic_and_sum_calculation_type?
      return if weight_sum.blank?

      calculate_average(score_sum, calculate_average(weight_sum, test_setting.maximum_score))
    else
      calculate_average(score_sum, @scores.size)
    end
  end
end
