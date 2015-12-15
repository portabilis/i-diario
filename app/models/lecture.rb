class Lecture
  extend ActiveModel::Naming

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
    attributes['id']
  end

  def name
    attributes['nome']
  end

  def grades
    RemoteGrade.all(attributes['series'])
  end

  def label
    "#{id} - #{name}"
  end

  def to_s
    name
  end

  def to_json
    {
      label: label,
      id: id,
      name: name,
      series: grades.map(&:to_json)
    }
  end
end
