class Select2PlansInput < Select2Input
  def input(wrapper_options)
    input_html_options[:placeholder] = I18n.t('simple_form.inputs.select2.plans.by_author')
    input_html_options[:value] = PlansAuthors::MY_PLANS

    super(wrapper_options)
  end

  def parse_collection
    options[:elements] = PlansAuthors.to_select.to_json

    super
  end
end
