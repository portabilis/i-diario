class Select2Input < SimpleForm::Inputs::StringInput
  def input
    input_html_options[:type] = "hidden"
    input_html_options[:style] = "width: 100%;" + (input_html_options[:style] || "")
    input_html_options[:data] = (input_html_options[:data] || {}).merge({elements: options[:elements]})

    @builder.text_field(attribute_name, input_html_options)
  end
end
