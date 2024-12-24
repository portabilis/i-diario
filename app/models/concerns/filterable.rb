module Filterable
  extend ActiveSupport::Concern

  module ClassMethods
    def filter_from_params(filtering_params)
      results = self.where(nil)
      filtering_params.each do |key, value|
        results = results.public_send(key, value) if value.present?
      end
      results
    end
  end
end
