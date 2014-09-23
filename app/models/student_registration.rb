class StudentRegistration
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

  def school_id
    attributes["escola_id"]
  end

  def student
    attributes["aluno_nome"]
  end

  def year
    attributes["ano"]
  end

  def classroom
    attributes["turma_nome"]
  end

  def series
    attributes["serie_nome"]
  end

  def course
    attributes["curso_nome"]
  end

  def school
    attributes["escola_nome"]
  end
end
