class StudentsSynchronizer < BaseSynchronizer
  def synchronize!
    update_records(
      HashDecorator.new(
        api.fetch['alunos']
      )
    )

    finish_worker
  end

  protected

  def api
    IeducarApi::Students.new(synchronization.to_api)
  end

  def update_records(collection)
    ActiveRecord::Base.transaction do
      collection.each do |student_record|
        student = Student.find_by(api_code: student_record.aluno_id)

        if student.present?
          student.update(
            name: student_record.nome_aluno,
            social_name: student_record.nome_social,
            avatar_url: student_record.foto_aluno,
            birth_date: student_record.data_nascimento,
            uses_differentiated_exam_rule: student_record.utiliza_regra_diferenciada
          )
        elsif student_record.nome_aluno.present?
          Student.create!(
            api_code: student_record.aluno_id,
            name: student_record.nome_aluno,
            social_name: student_record.nome_social,
            avatar_url: student_record.foto_aluno,
            birth_date: student_record.data_nascimento,
            api: true,
            uses_differentiated_exam_rule: student_record.utiliza_regra_diferenciada
          )
        end
      end
    end
  end
end
