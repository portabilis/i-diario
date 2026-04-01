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

      if student.nil? && !synchronization.full_synchronization?
        student = fetch_and_create_missing_student(student_enrollment_record.aluno_id)
      end

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

  def fetch_and_create_missing_student(student_id)
    students_api = IeducarApi::Students.new(synchronization.to_api, synchronization.full_synchronization)

    begin
      response = students_api.fetch_by_id(student_id)

      return nil if response.blank? || response['id'].blank?

      create_student_from_api_data(response)
    rescue StandardError => error
      Rails.logger.warn "Failed to fetch student #{student_id}: #{error.message}"
      nil
    end
  end

  def create_student_from_api_data(student_data)
    return nil if student_data['nome'].blank?

    begin
      Student.with_discarded.find_or_initialize_by(api_code: student_data['id']).tap do |student|
        student.name = student_data['nome']
        student.social_name = student_data['nome_social']
        student.avatar_url = student_data['url_foto_aluno']
        student.birth_date = student_data['data_nascimento'] if student_data['data_nascimento'].present?
        student.api = true
        student.uses_differentiated_exam_rule = false if student.uses_differentiated_exam_rule.nil?

        if student.changed?
          student.save!
          @students ||= {}
          @students[student_data['id'].to_s] = student
        end

        discarded = student_data['destroyed_at'].present?
        student.discard_or_undiscard(discarded)
      end
    rescue ActiveRecord::RecordNotUnique
      retry
    end
  end
end
