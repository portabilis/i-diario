ActiveRecord::Base.extend EnumerateIt

module EnumerateIt
  class Base
    def self.to_select
      elements = to_a.map { |arr| { id: arr[1], name: arr[0], text: arr[0] } }
      insert_empty_element(elements)
      elements
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