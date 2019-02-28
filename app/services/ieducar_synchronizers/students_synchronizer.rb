class StudentsSynchronizer < BaseSynchronizer
  def synchronize!
    update_students(
      HashDecorator.new(
        api.fetch['alunos']
      )
    )

    finish_worker
  end

  protected

  def api_class
    IeducarApi::Students
  end

  def update_students(students)
    ActiveRecord::Base.transaction do
      students.each do |student_record|
        Student.find_or_initialize_by(api_code: student_record.aluno_id).tap do |student|
          student.name = student_record.nome_aluno
          student.social_name = student_record.nome_social
          student.avatar_url = student_record.foto_aluno
          student.birth_date = student_record.data_nascimento
          student.uses_differentiated_exam_rule = student_record.utiliza_regra_diferenciada
          student.api = true
          student.save! if student.changed?

          student.discard_or_undiscard(student_record.deleted_at.present?)
        end
      end
    end
  end
end
