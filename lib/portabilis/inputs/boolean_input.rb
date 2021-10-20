module Portabilis
  module Inputs
    class BooleanInput < SimpleForm::Inputs::BooleanInput
      def input(wrapper_options)
        merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)

        if nested_boolean_style?
          build_hidden_field_for_checkbox +
            template.label_tag(nil, class: "checkbox") {
              build_check_box_without_hidden_field(merged_input_options) + inline_label + template.send(:content_tag, :i)
            }
        else
          build_check_box(unchecked_value, merged_input_options)
        end
      end
    end
  end
end
