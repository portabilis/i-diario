class Select2RemoteInput < SimpleForm::Inputs::StringInput
  def input(wrapper_options)
    input_html_options[:type] = 'hidden'
    input_html_options[:style] = 'width: 100%;' + (input_html_options[:style] || '')
    input_html_options[:data] = (input_html_options[:data] || {}).merge({ data_url: fetch_data_url })
    input_html_options[:data] = (input_html_options[:data] || {}).merge({ init_value: fetch_init_value })
    input_html_options[:data] = (input_html_options[:data] || {}).merge({ multiple: fetch_multiple })

    @builder.text_field(attribute_name, input_html_options)
  end

  protected

  def fetch_data_url
    options.fetch(:data_url, '').to_s
  end

  def fetch_init_value
    options.fetch(:init_value, '').to_s
  end

  def fetch_multiple
    options.fetch(:multiple, false)
  end
end
