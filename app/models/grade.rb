class Grade
  attr_accessor :attributes

  def self.all(collection)
    collection.map do |record|
      new(record)
    end
  end

  def initialize(attributes)
    self.attributes = attributes
  end

  def id
    attributes["id"]
  end

  def name
    attributes["nome"]
  end

  def id_and_name
    "#{id} - #{name}"
  end
end
