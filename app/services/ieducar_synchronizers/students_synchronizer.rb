class StudentsSynchronizer < BaseSynchronizer
  def synchronize!
    update_records api.fetch["alunos"]
  end

  protected

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
            birth_date: record["data_nascimento"]
          )
        elsif record["nome_aluno"].present?
          students.create!(
            api_code: record["aluno_id"],
            name: record["nome_aluno"],
            avatar_url: record["foto_aluno"],
            birth_date: record["data_nascimento"],
            api: true
          )
        end
      end
    end

    finish_worker('StudentsSynchronizer')
  end

  def students(klass = Student)
    klass
  end
end
