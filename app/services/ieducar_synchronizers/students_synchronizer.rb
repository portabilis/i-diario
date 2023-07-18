class StudentsSynchronizer < BaseSynchronizer
  def synchronize!
    update_students(
      HashDecorator.new(
        api.fetch(
          escola: unity_api_code
        )['alunos']
      )
    )
  end

  private

  def api_class
    IeducarApi::Students
  end

  def update_students(students)
    allow_create_users_for_students = GeneralConfiguration.current.create_users_for_students_when_synchronize

    students.each do |student_record|
      next if student_record.nome_aluno.blank?

      Student.with_discarded.find_or_initialize_by(api_code: student_record.aluno_id).tap do |student|
        student.name = student_record.nome_aluno
        student.social_name = student_record.nome_social
        student.avatar_url = student_record.foto_aluno
        student.birth_date = student_record.data_nascimento
        student.api = true

        student.uses_differentiated_exam_rule = false if student.uses_differentiated_exam_rule.nil?
        student.save! if student.changed?

        create_users(student) if student.changed? && allow_create_users_for_students

        discarded = student_record.deleted_at.present?

        student.discard_or_undiscard(discarded)
      end
    end
  end

  def create_users(student)
    UserForStudentCreatorWorker.perform_in(1.second, entity_id, student)
  end
end
