class StudentEnrollmentSynchronizer < BaseSynchronizer
  def synchronize!
    update_records api.fetch(ano: years.first, escola: unity_api_code)['matriculas']
  end

  def self.synchronize_in_batch!(synchronization, worker_batch, years = nil, unity_api_code = nil, entity_id = nil)
    super do
      years.each do |year|
        Unity.with_api_code.each do |unity|
          StudentEnrollmentSynchronizer.new(
            synchronization,
            worker_batch,
            [year],
            unity.api_code,
            entity_id
          ).synchronize!
        end
      end
    end
  end

  protected

  def worker_name
    "#{self.class}-#{years.first}-#{unity_api_code}"
  end

  def api
    IeducarApi::StudentEnrollments.new(synchronization.to_api)
  end

  def update_records(collection)
    return if collection.blank?

    updated_student_ids = []

    collection.each do |record|
      if (student_enrollment = student_enrollments.find_by(api_code: record['matricula_id']))
        update_existing_student_enrollment(record, student_enrollment, updated_student_ids)
      else
        create_new_student_enrollment(record, updated_student_ids)
      end
    end

    updated_student_ids.uniq.each do |student_id|
      classroom_ids = StudentEnrollmentClassroom.by_student(student_id)
                                                .pluck(:classroom_id)
                                                .compact
                                                .uniq

      classroom_ids.each do |classroom_id|
        DeleteInvalidPresenceRecordWorker.perform_async(
          entity_id,
          student_id,
          classroom_id
        )
      end
    end
  end

  def student_enrollments(klass = StudentEnrollment)
    klass
  end

  def student_enrollment_classrooms(klass = StudentEnrollmentClassroom)
    klass
  end

  def create_new_student_enrollment(record, updated_student_ids)
    return unless student_id(record)

    updated_student_ids << student_id(record)

    student_enrollment = student_enrollments.create!(
      api_code: record['matricula_id'],
      status: record['situacao'],
      student_id: student_id(record),
      student_code: record['aluno_id'],
      changed_at: record['data_atualizacao'].to_s,
      active: record['ativo']
    )

    return if record['enturmacoes'].blank?

    record['enturmacoes'].each do |record_classroom|
      student_enrollment.student_enrollment_classrooms.create!(
        api_code: record_classroom['sequencial'],
        classroom_id: Classroom.find_by(api_code: record_classroom['turma_id']).try(:id),
        classroom_code: record_classroom['turma_id'],
        joined_at: record_classroom['data_entrada'],
        left_at: record_classroom['data_saida'],
        changed_at: record_classroom['data_atualizacao'].to_s,
        sequence: record_classroom['sequencial_fechamento'],
        show_as_inactive_when_not_in_date: record_classroom['apresentar_fora_da_data'],
        period: record_classroom['turno_id']
      )
    end
  end

  def update_existing_student_enrollment(record, student_enrollment, updated_student_ids)
    return unless student_id(record)

    date_changed = record['data_atualizacao'].blank? ||
                   student_enrollment.changed_at.blank? ||
                   record['data_atualizacao'].to_s > student_enrollment.changed_at.to_s

    if date_changed
      student_enrollment.update(
        status: record['situacao'],
        student_id: student_id(record),
        student_code: record['aluno_id'],
        changed_at: record['data_atualizacao'].to_s,
        active: record['ativo']
      )
    end

    return if record['enturmacoes'].blank?

    updated_student_ids << student_id(record)
    any_updated_or_new_record = false

    record['enturmacoes'].each do |record_classroom|
      if (student_enrollment_classroom = student_enrollment.student_enrollment_classrooms
                                                           .find_by(api_code: record_classroom['sequencial']))

        any_updated_or_new_record = record_classroom['data_atualizacao'].blank? ||
                                    record_classroom['data_atualizacao'].to_s >
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

        record['enturmacoes'].each do |record_classroom|
          create_student_entrrollment_classroom(student_enrollment, record_classroom, record_classroom['turno_id'])
        end
      end
    else
      record['enturmacoes'].each do |record_classroom|
        next if student_enrollment.student_enrollment_classrooms.find_by(api_code: record_classroom['sequencial'])

        create_student_entrrollment_classroom(student_enrollment, record_classroom, record_classroom['turno_id'])
      end
    end
  end

  private

  def student_id(record)
    @student_ids ||= {}
    @student_ids[record['aluno_id']] ||= Student.find_by(api_code: record['aluno_id']).try(:id)
  end

  def create_student_entrrollment_classroom(student_enrollment, record_classroom, period)
    student_enrollment.student_enrollment_classrooms.create!(
      api_code: record_classroom['sequencial'],
      classroom_id: Classroom.find_by(api_code: record_classroom['turma_id']).try(:id),
      classroom_code: record_classroom['turma_id'],
      joined_at: record_classroom['data_entrada'],
      left_at: record_classroom['data_saida'],
      changed_at: record_classroom['data_atualizacao'].to_s,
      sequence: record_classroom['sequencial_fechamento'],
      show_as_inactive_when_not_in_date: record_classroom['apresentar_fora_da_data'],
      period: period
    )
  end
end
