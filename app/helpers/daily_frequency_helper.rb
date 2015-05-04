module DailyFrequencyHelper

  def number_of_classes_elements number_of_classes
    elements = []
    (1..number_of_classes).each do |i|
      elements << {id: i, name: i, text: i}
    end
    elements.to_json
  end
end