module Portabilis
  module Inputs
    class DateInput < SimpleForm::Inputs::StringInput
      def input
        @builder.text_field(attribute_name, input_html_options)
      end

      protected

      def input_html_classes
        super.unshift("string input-small form-control")
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
