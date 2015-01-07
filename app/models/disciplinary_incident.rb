class DisciplinaryIncident
  extend ActiveModel::Naming

  attr_accessor :attributes

  delegate :name, to: :student, allow_nil: true, prefix: true

  def self.all(collection)
    collection.map do |record|
      new(record)
    end
  end

  def initialize(attributes)
    self.attributes = attributes
  end

  def student
    Student.find_by(api_code: attributes["aluno_id"])
  end

  def date
    attributes["data_hora"]
  end

  def kind
    attributes["tipo"]
  end

  def description
    attributes["descricao"]
  end

  def self.columns
    [:student_name, :date, :kind, :description]
  end
end
