class ConceptualExamStudentDecorator
  include Decore
  include Decore::Proxy

  def data_for_select2
    value_options.ordered.map do |value_option|
      {
        id: value_option.value,
        name: value_option.to_s,
        text: value_option.to_s
      }
    end.to_json
  end
end
