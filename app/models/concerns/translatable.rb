module Translatable
  extend ActiveSupport::Concern

  module ClassMethods
    def human_attribute_name(column_name, options = {})
      Translator.t("activerecord.attributes.#{model_name.param_key}.#{column_name}")
    end
  end
end
