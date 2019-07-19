class RemoteGrade
  extend ActiveModel::Naming

  attr_accessor :attributes

  def self.all(collection)
    return [] if collection.blank?

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

  def label
    "#{id} - #{name}"
  end

  def school_classes
    SchoolClass.all(attributes['turmas'])
  end

  def to_s
    name
  end

  def to_json
    {
      label: label,
      id: id,
      name: name,
      school_classes: school_classes.map(&:to_json)
    }
  end
end
