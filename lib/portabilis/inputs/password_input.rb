module Portabilis
  module Inputs
    class PasswordInput < SimpleForm::Inputs::StringInput
      private

      def input_html_classes
        super.unshift("form-control")
      end
    end
  end
end
