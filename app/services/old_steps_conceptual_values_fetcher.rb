class OldStepsConceptualValuesFetcher
  def initialize(classroom, student, current_step)
    @classroom = classroom
    @student = student
    @current_step = current_step
  end

  def fetch
    old_steps.map do |step|
      {
        description: "#{step}",
        values: values_by_step(step)
      }
    end
  end

  private

  def values_by_step(step)
    conceptual_exam_values = ConceptualExamValue.joins(:conceptual_exam)
      .merge(
        ConceptualExam.where(student_id: @student.id)
                      .by_classroom(@classroom.id)
                      .by_step_id(@classroom, step.id)
      )

    values = {}
    conceptual_exam_values.ordered.each do |value|
      values["#{value.discipline_id}"] = rounding_table_value_of(value.value)
    end
    values
  end

  def old_steps
    @old_steps ||= StepsFetcher.new(@classroom).old_steps(@current_step.step_number)
  end

  def rounding_table_value_of(value)
    rounding_table_values["#{value}"] || "#{value}"
  end

  def rounding_table_values
    @rounding_table_values ||= begin
      hash = {}
      (rounding_table.try(:rounding_table_values)||[]).each do |rouding_table_value|
        hash["#{rouding_table_value.value}"] = "#{rouding_table_value}"
      end
      hash
    end
  end

  def rounding_table
    @rounding_table ||= ExamRuleFetcher.fetch(@classroom, @student).try(:conceptual_rounding_table)
  end
end
