module Portabilis
  module ParamsHandler
      def fetch_params_to_attributes(attrs, params)
        attrs.each do |param|
          var_name = "@#{param[:param]}"

          value = params.fetch(
            param[:param],
            param.fetch(:default, nil)
          )

          self.instance_variable_set(var_name, value)
        end
      end
  end
end
