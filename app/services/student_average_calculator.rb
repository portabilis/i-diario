class StudentAverageCalculator
  def initialize(student)
    @student = student
  end

  def calculate(classroom, discipline, step)
    student_notes_query = StudentNotesQuery.new(student, discipline, classroom, step.start_at, step.end_at)
    @daily_note_students = student_notes_query.daily_note_students + student_notes_query.transfer_notes +
      student_notes_query.previous_enrollments_daily_note_students
    test_setting = test_setting(classroom, step)

    @recovery_lowest_note_in_step = student_notes_query.recovery_lowest_note_in_step(step)
    @recovery_diary_records = student_notes_query.recovery_diary_records

    return if daily_note_students.blank? && recovery_diary_records.blank? && recovery_lowest_note_in_step.blank?

    result = calculate_average_by_settings(test_setting)

    return if result.blank?

    result = ComplementaryExamCalculator.new(
      [AffectedScoreTypes::STEP_AVERAGE, AffectedScoreTypes::BOTH],
      student.id,
      discipline.id,
      classroom.id,
      step
    ).calculate(result)

    ScoreRounder.new(classroom, RoundedAvaliations::NUMERICAL_EXAM, step).round(result)
  end

  private

  attr_accessor :student, :daily_note_students, :recovery_diary_records, :recovery_lowest_note_in_step

  def weight_sum
    avaliations = []

    daily_note_students.each do |daily_note_student|
      next if avaliation_exempted?(daily_note_student.daily_note.avaliation)

      avaliations << { value: daily_note_student.daily_note.avaliation.weight, avaliation_id: daily_note_student.daily_note.avaliation.id }
    end

    recovery_diary_records.each do |recovery_diary_record|
      next if avaliation_exempted?(recovery_diary_record.avaliation_recovery_diary_record.avaliation)

      avaliations << { value: recovery_diary_record.avaliation_recovery_diary_record.avaliation.weight, avaliation_id: recovery_diary_record.avaliation_recovery_diary_record.avaliation.id }
    end

    weights = extract_weight_avaliations(avaliations)

    weights.reduce(:+)
  end

  def score_sum
    avaliations = []
    @scores = []

    daily_note_students.each do |daily_note_student|
      next if avaliation_exempted?(daily_note_student.daily_note.avaliation)
      next if daily_note_student.note.blank? && daily_note_student.transfer_note.present?

      avaliations << { value: daily_note_student.recovered_note, avaliation_id: daily_note_student.daily_note.avaliation.id }
    end

    recovery_diary_records.each do |recovery_diary_record|
      next if avaliation_exempted?(recovery_diary_record.avaliation_recovery_diary_record.avaliation)
      next unless (score = recovery_diary_record.students.find_by(student_id: student.id)&.score)

      avaliations << { value: score, avaliation_id: recovery_diary_record.avaliation_recovery_diary_record.avaliation.id }
    end

    @scores = extract_note_avaliations(avaliations)
    multiplied_scores = @scores.map { |score| score * 100 }
    total = multiplied_scores.compact.sum
    total/100
  end

  def extract_weight_avaliations(avaliations)
    use_unique_avaliations(avaliations)
  end

  def extract_note_avaliations(avaliations)
    values = use_unique_avaliations(avaliations)

    if recovery_lowest_note_in_step.present?
      lowest_note = nil
      index_lowest_note = 0

      values.each_with_index do |value, index|
        lowest_note = value if lowest_note.nil?

        if value < lowest_note
          index_lowest_note = index
          lowest_note = value
        end
      end

      if recovery_lowest_note_in_step.score.present?
        if recovery_lowest_note_in_step.score > values[index_lowest_note]
          values[index_lowest_note] = recovery_lowest_note_in_step.score
        end
      end
    end

    values
  end

  def use_unique_avaliations(avaliations)
    values = []
    values << 0 if avaliations.blank?
    avaliations.uniq.group_by { |k, v| k[:avaliation_id] }.each do |avaliation|
      value = 0

      if avaliation.last.count > 1
        avaliation.last.each { |array| value = array[:value] if value < array[:value] }
      elsif avaliation.last.last[:value].present?
        value = avaliation.last.last[:value]
      end

      values << value
    end

    values
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
