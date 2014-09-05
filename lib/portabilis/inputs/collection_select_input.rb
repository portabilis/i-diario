module Portabilis
  module Inputs
    class CollectionSelectInput < SimpleForm::Inputs::CollectionSelectInput
      private

      def input_html_classes
        super.unshift("form-control input-sm")
      end
    end
  end
end
