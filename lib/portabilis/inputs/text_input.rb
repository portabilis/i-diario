module Portabilis
  module Inputs
    class TextInput < SimpleForm::Inputs::TextInput
      private

      def input_html_classes
        super.unshift('form-control col col-sm-12')
      end

      def input_html_options
        super.tap do |options|
          options[:rows] ||= 5
        end
      end
    end
  end
end
