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
      .merge(ConceptualExam.where(student_id: @student.id))
      .merge(ConceptualExam.by_classroom(@classroom.id))

    if @classroom.calendar
      conceptual_exam_values = conceptual_exam_values.merge(ConceptualExam.by_school_calendar_classroom_step(step.id))
    else
      conceptual_exam_values = conceptual_exam_values.merge(ConceptualExam.by_school_calendar_step(step.id))
    end
    values = {}
    conceptual_exam_values.ordered.each do |value|
      values["#{value.discipline_id}"] = rounding_table_value_of(value.value)
    end
    values
  end

  def old_steps
    @old_steps ||= @classroom.calendar ? old_school_calendar_classroom_steps : old_school_calendar_steps
  end

  def old_school_calendar_classroom_steps
    @current_step.school_calendar_classroom
      .steps
      .where(SchoolCalendarClassroomStep.arel_table[:start_at].lt(@current_step.start_at))
      .ordered
  end

  def old_school_calendar_steps
    @current_step.school_calendar
      .steps
      .where(SchoolCalendarStep.arel_table[:start_at].lt(@current_step.start_at))
      .ordered
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
    @rounding_table ||= @classroom.exam_rule.try(:rounding_table)
  end
end
