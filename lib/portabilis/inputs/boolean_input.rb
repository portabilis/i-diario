module Portabilis
  module Inputs
    class BooleanInput < SimpleForm::Inputs::BooleanInput
      def input
        if nested_boolean_style?
          build_hidden_field_for_checkbox +
            template.label_tag(nil, class: "checkbox") {
              build_check_box_without_hidden_field + inline_label + template.send(:content_tag, :i)
            }
        else
          build_check_box
        end
      end
    end
  end
end
