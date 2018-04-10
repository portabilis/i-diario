module ConceptualExamValueHelper
  def conceptual_exam_value_student_name_class(conceptual_exam_value)
    if conceptual_exam_value.exempted_discipline
      'exempted-student-from-discipline'
    else
      ''
    end
  end

  def conceptual_exam_value_student_name(conceptual_exam_value)
    if conceptual_exam_value.exempted_discipline
      "*#{conceptual_exam_value.discipline.description}"
    else
      "#{conceptual_exam_value.discipline.description}"
    end
  end
end
