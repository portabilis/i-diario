class Lecture
  attr_accessor :attributes

  def self.all(collection)
    return [] unless collection

    collection.map do |record|
      new(record)
    end
  end

  def initialize(attributes)
    self.attributes = attributes
  end

  def id
    "#{raw_id}\\#{name}"
  end

  def raw_id
    attributes["id"]
  end

  def name
    attributes["nome"]
  end

  def grades
    Grade.all(attributes["series"])
  end

  def label
    "#{raw_id} - #{name}"
  end

  def to_s
    name
  end

  def to_json
    {
      label: label,
      id: id,
      name: name,
      series: grades
    }
  end
end
