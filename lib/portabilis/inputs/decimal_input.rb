module Portabilis
  module Inputs
    class DecimalInput < SimpleForm::Inputs::StringInput
      private

      def input_html_classes
        super.unshift("decimal form-control")
      end
    end
  end
end
