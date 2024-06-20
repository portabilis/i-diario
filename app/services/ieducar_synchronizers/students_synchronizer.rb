class StudentsSynchronizer < BaseSynchronizer
  def synchronize!
    update_students(
      HashDecorator.new(
        api.fetch(
          escola: unity_api_code
        )['alunos']
      )
    )
  rescue IeducarApi::Base::ApiError => error
    synchronization.mark_as_error!(error.message)
  end

  private

  def api_class
    IeducarApi::Students
  end

  def update_students(students)
    allow_create_users_for_students = GeneralConfiguration.current.create_users_for_students_when_synchronize
    @student_users ||= User.joins(:students).where(students: { api_code: students.map(&:aluno_id) }) if allow_create_users_for_students

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

        discarded = student_record.deleted_at.present?

        student.discard_or_undiscard(discarded)

        if student.discarded?
          student_enrollments = StudentEnrollment.where(student_id: student.id)
          student_enrollment_classrooms = StudentEnrollmentClassroom.where(
            student_enrollment_id: student_enrollments.map(&:id)
          )

          student_enrollments.each(&:discard)
          student_enrollment_classrooms.each(&:discard)
        end

        create_users(student.id) if allow_create_users_for_students && student_user_new?(student) && !student.discarded?
      end
    end
  end

  def create_users(student_id)
    UserForStudentCreatorWorker.perform_in(1.second, entity_id, student_id)
  end

  def student_user_new?(student)
    true unless @student_users.map(&:student_id).include?(student.id)
  end
end
