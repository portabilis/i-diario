module Portabilis
  module Inputs
    class DateInput < SimpleForm::Inputs::StringInput
      def input(wrapper_options)
        label = template.content_tag(:label, '', for: attribute_name, class: 'fa fa-calendar')
        input = @builder.text_field(attribute_name, input_html_options)

        template.content_tag(
          :div,
          label + input,
          class: 'icon-addon')
      end

      protected

      def input_html_classes
        super.unshift('string input-small form-control datepicker')
      end

      def input_html_options
        super.tap do |options|
          options[:size] ||= 10
          options[:type] ||= :text
          options[:data] ||= {}
          options[:data][:mask] ||= '99/99/9999'
        end
      end
    end
  end
end
