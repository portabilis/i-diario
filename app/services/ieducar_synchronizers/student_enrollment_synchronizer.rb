class StudentEnrollmentSynchronizer < BaseSynchronizer
  def synchronize!
    update_records(
      HashDecorator.new(
        api.fetch(
          ano: years.first,
          escola: unity_api_code
        )['matriculas']
      )
    )

    finish_worker
  end

  def self.synchronize_in_batch!(synchronization, worker_batch, years = nil, _unity_api_code = nil, entity_id = nil)
    years.each do |year|
      Unity.with_api_code.each do |unity|
        StudentEnrollmentSynchronizer.synchronize!(
          synchronization,
          worker_batch,
          [year],
          unity.api_code,
          entity_id
        )
      end
    end
  end

  protected

  def worker_name
    "#{self.class}-#{years.first}-#{unity_api_code}"
  end

  def api_class
    IeducarApi::StudentEnrollments
  end

  def update_records(collection)
    return if collection.blank?

    @updated_records = []

    collection.each do |record|
      student_enrollment = StudentEnrollment.find_by(api_code: record.matricula_id)

      if student_enrollment.present?
        update_existing_student_enrollment(
          record,
          student_enrollment
        )
      else
        create_new_student_enrollment(
          record
        )
      end
    end

    @updated_records.uniq.each do |student_id, classroom_id|
      DeleteInvalidPresenceRecordWorker.perform_async(
        entity_id,
        student_id,
        classroom_id
      )
    end
  end

  def create_new_student_enrollment(record)
    student_id = student(record.aluno_id).try(:id)

    return if student_id.blank?

    student_enrollment = StudentEnrollment.create!(
      api_code: record.matricula_id,
      status: record.situacao,
      student_id: student_id,
      student_code: record.aluno_id,
      changed_at: record.data_atualizacao.to_s,
      active: record.ativo
    )

    return if record.enturmacoes.blank?

    record.enturmacoes.each do |record_classroom|
      classroom_id = classroom(record_classroom.turma_id).try(:id)

      student_enrollment.student_enrollment_classrooms.create!(
        api_code: record_classroom.sequencial,
        classroom_id: classroom_id,
        classroom_code: record_classroom.turma_id,
        joined_at: record_classroom.data_entrada,
        left_at: record_classroom.data_saida,
        changed_at: record_classroom.data_atualizacao.to_s,
        sequence: record_classroom.sequencial_fechamento,
        show_as_inactive_when_not_in_date: record_classroom.apresentar_fora_da_data,
        period: record.turno_id
      )

      @updated_records << [student_id, classroom_id]
    end
  end

  def update_existing_student_enrollment(record, student_enrollment)
    student_id = student(record.aluno_id).try(:id)

    return if student_id.blank?

    date_changed = record.data_atualizacao.blank? ||
                   student_enrollment.changed_at.blank? ||
                   record.data_atualizacao.to_s > student_enrollment.changed_at.to_s

    if date_changed
      student_enrollment.update(
        status: record.situacao,
        student_id: student_id,
        student_code: record.aluno_id,
        changed_at: record.data_atualizacao.to_s,
        active: record.ativo
      )
    end

    return if record.enturmacoes.blank?

    any_updated_or_new_record = false

    record.enturmacoes.each do |record_classroom|
      student_enrollment_classroom = student_enrollment.student_enrollment_classrooms
                                                       .find_by(api_code: record_classroom.sequencial)
      if student_enrollment_classroom.present?
        any_updated_or_new_record = record_classroom.data_atualizacao.blank? ||
                                    record_classroom.data_atualizacao.to_s >
                                    student_enrollment_classroom.changed_at.to_s
        break if any_updated_or_new_record
      else
        any_updated_or_new_record = true
        break
      end
    end

    if any_updated_or_new_record
      ActiveRecord::Base.transaction do
        student_enrollment.student_enrollment_classrooms.destroy_all

        record.enturmacoes.each do |record_classroom|
          create_student_enrrollment_classroom(
            student_enrollment,
            record_classroom,
            record.turno_id
          )
        end
      end
    else
      record.enturmacoes.each do |record_classroom|
        next if student_enrollment.student_enrollment_classrooms.find_by(api_code: record_classroom.sequencial)

        create_student_enrrollment_classroom(
          student_enrollment,
          record_classroom,
          record.turno_id
        )
      end
    end
  end

  private

  def create_student_enrrollment_classroom(student_enrollment, record_classroom, period)
    classroom_id = classroom(record_classroom.turma_id).try(:id)

    student_enrollment.student_enrollment_classrooms.create!(
      api_code: record_classroom.sequencial,
      classroom_id: classroom_id,
      classroom_code: record_classroom.turma_id,
      joined_at: record_classroom.data_entrada,
      left_at: record_classroom.data_saida,
      changed_at: record_classroom.data_atualizacao.to_s,
      sequence: record_classroom.sequencial_fechamento,
      show_as_inactive_when_not_in_date: record_classroom.apresentar_fora_da_data,
      period: period
    )

    @updated_records << [student_enrollment.student_id, classroom_id]
  end

  def student(api_code)
    @student_ids ||= {}
    @student_ids[api_code] ||= Student.find_by(api_code: api_code)
  end

  def classroom(api_code)
    @classroom_ids ||= {}
    @classroom_ids[api_code] ||= Classroom.find_by(api_code: api_code)
  end
end
