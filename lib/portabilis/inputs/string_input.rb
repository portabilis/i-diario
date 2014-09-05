module Portabilis
  module Inputs
    class StringInput < SimpleForm::Inputs::StringInput
      protected

      include Portabilis::MaskToInputs

      private

      def input_html_classes
        super.unshift("form-control")
      end
    end
  end
end
