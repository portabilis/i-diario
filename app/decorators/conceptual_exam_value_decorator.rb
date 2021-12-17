class ConceptualExamValueDecorator
  include Decore
  include Decore::Proxy

  def data_for_select2
    exam_rule = conceptual_exam.classroom.exam_rule

    if conceptual_exam.student.try(:uses_differentiated_exam_rule)
      exam_rule = exam_rule.differentiated_exam_rule || exam_rule
    end

    return [] if exam_rule.blank?

    rounding_table = exam_rule.conceptual_rounding_table

    if rounding_table.present?
      elements = []
      rounding_table.rounding_table_values.map { |rounding_table_value|
        elements << { id: rounding_table_value.value, name: rounding_table_value.to_s, text: rounding_table_value.to_s }
      }
      add_empty_element(elements)
    else
      []
    end
  end

  def add_empty_element(elements)
    empty_element = { id: "empty", name: "<option></option>", text: "" }
    elements.insert(0, empty_element)
    elements.to_json
  end
end
