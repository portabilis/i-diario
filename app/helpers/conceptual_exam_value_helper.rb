module ConceptualExamValueHelper
  def conceptual_exam_value_exempted?(conceptual_exam_value)
    conceptual_exam_value.exempted_discipline.to_s == 'true'
  end

  def conceptual_exam_value_in_dependence?(conceptual_exam_value)
    conceptual_exam_dependence_discipline_ids.include?(conceptual_exam_value.discipline_id)
  end

  # Mantidos para a tela de avaliacoes conceituais em lote, que ainda usa asteriscos
  def conceptual_exam_value_student_name_class(conceptual_exam_value)
    conceptual_exam_value_exempted?(conceptual_exam_value) ? 'exempted-student-from-discipline' : ''
  end

  def conceptual_exam_value_student_name(conceptual_exam_value)
    description = conceptual_exam_value.discipline.description
    conceptual_exam_value_exempted?(conceptual_exam_value) ? "****#{description}" : description
  end
end
