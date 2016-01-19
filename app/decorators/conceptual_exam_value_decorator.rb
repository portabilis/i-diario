class ConceptualExamValueDecorator
  include Decore
  include Decore::Proxy

  def data_for_select2
    conceptual_exam.classroom.exam_rule
      .rounding_table
      .rounding_table_values
      .map do |rounding_table_value|
      {
        id: rounding_table_value.value,
        name: rounding_table_value.to_s,
        text: rounding_table_value.to_s
      }
      end
      .to_json
  end
end
