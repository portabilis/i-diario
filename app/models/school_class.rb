class SchoolClass
  extend ActiveModel::Naming

  attr_accessor :attributes

  def self.all(collection)
    (collection || []).map do |record|
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
    attributes["cod_turma"]
  end

  def name
    attributes["nm_turma"]
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
      name: name
    }
  end
end
