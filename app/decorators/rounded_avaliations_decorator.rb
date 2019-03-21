class RoundedAvaliationsDecorator
  def self.data_for_select2
    avaliations = RoundedAvaliations.to_a.map { |text, value| { id: value, name: text } }
    insert_empty_element(avaliations) if avaliations.any?

    avaliations.to_json
  end

  def self.insert_empty_element(elements)
    empty_element = { id: 'empty', name: '<option></option>' }
    elements.insert(0, empty_element)
  end
end
