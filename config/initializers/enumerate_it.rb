ActiveRecord::Base.extend EnumerateIt

module EnumerateIt
  class Base
    def self.to_select(include_empty_element = true)
      elements = to_a.map { |arr| { id: arr[1], name: arr[0], text: arr[0] } }
      insert_empty_element(elements) if include_empty_element
      elements
    end

    def self.to_select_specific_values(include_empty_element = true, keys_array)
      elements = to_a.map { |arr| { id: arr[1], name: arr[0], text: arr[0] } if keys_array.include? arr[1] }
      insert_empty_element(elements) if include_empty_element
      elements.compact
    end

    def self.to_hash
      Hash[to_a]
    end

    private

    def self.insert_empty_element(elements)
      empty_element = { id: 'empty', name: '<option></option>', text: '' }
      elements.insert(0, empty_element)
    end
  end
end