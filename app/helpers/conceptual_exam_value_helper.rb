module ConceptualExamValueHelper
  def conceptual_exam_value_exempted?(conceptual_exam_value)
    conceptual_exam_value.exempted_discipline.to_s == 'true'
  end

  def conceptual_exam_value_in_dependence?(conceptual_exam_value)
    conceptual_exam_dependence_discipline_ids.include?(conceptual_exam_value.discipline_id)
  end
end
