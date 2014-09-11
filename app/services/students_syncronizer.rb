class StudentsSyncronizer
  def self.syncronize!(collection)
    new(collection).syncronize!
  end

  def initialize(collection)
    self.collection = collection
  end

  def syncronize!
    ActiveRecord::Base.transaction do
      collection.each do |record|
        if student = students.find_by(api_code: record["aluno_id"])
          student.update(name: record["nome_aluno"])
        elsif record["nome_aluno"].present?
          students.create!(
            api_code: record["aluno_id"],
            name: record["nome_aluno"],
            api: true
          )
        end
      end
    end
  end

  protected

  attr_accessor :collection

  def students(klass = Student)
    klass
  end
end
