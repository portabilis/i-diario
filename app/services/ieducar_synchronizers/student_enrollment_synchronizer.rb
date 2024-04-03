class StudentEnrollmentSynchronizer < BaseSynchronizer
  def synchronize!
    update_student_enrollments(
      HashDecorator.new(
        api.fetch(
          ano: year,
          escola: unity_api_code
        )['matriculas']
      )
    )
  rescue IeducarApi::Base::ApiError => error
    synchronization.mark_as_error!(error.message)
  end

  private

  def api_class
    IeducarApi::StudentEnrollments
  end

  def update_student_enrollments(student_enrollments)
    return if student_enrollments.blank?

    student_enrollments.each do |student_enrollment_record|
      student = student(student_enrollment_record.aluno_id)

      if student.nil? || student.id.blank? || student.discarded?
        StudentEnrollment.find_by(api_code: student_enrollment_record.matricula_id)&.discard

        next
      end


      StudentEnrollment.with_discarded.find_or_initialize_by(
        api_code: student_enrollment_record.matricula_id
      ).tap do |student_enrollment|
        student_enrollment.status = student_enrollment_record.situacao
        student_enrollment.student_id = student.id
        student_enrollment.student_code = student_enrollment_record.aluno_id
        student_enrollment.changed_at = student_enrollment_record.updated_at
        student_enrollment.active = student_enrollment_record.ativo
        student_enrollment.save! if student_enrollment.changed?
        student_enrollment.entity_id = entity_id

        student_enrollment.discard_or_undiscard(student_enrollment_record.deleted_at.present?)
      end
    end
  end
end
