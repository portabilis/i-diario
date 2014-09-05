module Portabilis
  module Inputs
    class RadioButtons < SimpleForm::Inputs::CollectionRadioButtonsInput
      private

      def input_html_classes
        super.unshift("radio-inline")
      end
    end
  end
end
