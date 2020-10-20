module Searchable
  extend ActiveSupport::Concern

  included do
    def self.split_search(input)
      input.split.map { |w| "\"#{w}\"" }.join(':* & ') << ':*'
    end
  end
end
