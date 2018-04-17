class StudentsSynchronizer
  def self.synchronize!(synchronization)
    new(synchronization).synchronize!
  end

  def initialize(synchronization)
    self.synchronization = synchronization
  end

  def synchronize!
    update_records api.fetch["alunos"]
  end

  protected

  attr_accessor :synchronization

  def api
    IeducarApi::Students.new(synchronization.to_api)
  end

  def update_records(collection)
    ActiveRecord::Base.transaction do
      collection.each do |record|
        if student = students.find_by(api_code: record["aluno_id"])
          student.update(
            name: record["nome_aluno"],
            avatar_url: record["foto_aluno"],
            birth_date: record["data_nascimento"],
            uses_differentiated_exam_rule: record["utiliza_regra_diferenciada"]
          )
        elsif record["nome_aluno"].present?
          students.create!(
            api_code: record["aluno_id"],
            name: record["nome_aluno"],
            avatar_url: record["foto_aluno"],
            birth_date: record["data_nascimento"],
            api: true,
            uses_differentiated_exam_rule: record["utiliza_regra_diferenciada"]
          )
        end
      end
    end
  end

  def students(klass = Student)
    klass
  end
end
