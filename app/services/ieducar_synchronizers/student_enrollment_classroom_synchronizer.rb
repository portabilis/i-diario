class StudentEnrollmentClassroomSynchronizer < BaseSynchronizer
  def synchronize!
    update_student_enrollment_classrooms(
      HashDecorator.new(
        api.fetch(
          ano: year,
          escola: unity_api_code
        )['enturmacoes']
      )
    )
  end

  private

  def api_class
    IeducarApi::StudentEnrollmentClassrooms
  end

  def update_student_enrollment_classrooms(student_enrollment_classrooms)
    return if student_enrollment_classrooms.blank?

    changed_student_enrollment_classrooms = []

    student_enrollment_classrooms.each do |student_enrollment_classroom_record|
      classroom_id = classroom(student_enrollment_classroom_record.turma_id).try(:id)
      student_enrollment = student_enrollment(student_enrollment_classroom_record.matricula_id)

      next if student_enrollment.blank?

      StudentEnrollmentClassroom.with_discarded.find_or_initialize_by(
        api_code: student_enrollment_classroom_record.id
      ).tap do |student_enrollment_classroom|
        student_enrollment_classroom.student_enrollment = student_enrollment
        student_enrollment_classroom.classroom_id = classroom_id
        student_enrollment_classroom.classroom_code = student_enrollment_classroom_record.turma_id
        student_enrollment_classroom.joined_at = student_enrollment_classroom_record.data_entrada
        student_enrollment_classroom.left_at = student_enrollment_classroom_record.data_saida
        student_enrollment_classroom.changed_at = student_enrollment_classroom_record.updated_at
        student_enrollment_classroom.sequence = student_enrollment_classroom_record.sequencial_fechamento
        student_enrollment_classroom.index = student_enrollment_classroom_record.sequencial
        student_enrollment_classroom.show_as_inactive_when_not_in_date =
          student_enrollment_classroom_record.apresentar_fora_da_data
        student_enrollment_classroom.period = student_enrollment_classroom_record.turno_id

        if student_enrollment_classroom.changed?
          student_enrollment_classroom.save!
          changed_student_enrollment_classrooms << [student_enrollment.student_id, classroom_id]
        end

        student_enrollment_classroom.entity_id = entity_id

        student_enrollment_classroom.discard_or_undiscard(student_enrollment_classroom_record.deleted_at.present?)
      end
    end

    delete_invalid_presence_records(changed_student_enrollment_classrooms)
  end

  def delete_invalid_presence_records(changed_student_enrollment_classrooms)
    changed_student_enrollment_classrooms.uniq.each do |student_id, classroom_id|
      next if student_id.blank? || classroom_id.blank?

      DeleteInvalidPresenceRecordWorker.perform_in(
        1.second,
        entity_id,
        student_id,
        classroom_id
      )
    end
  end
end
