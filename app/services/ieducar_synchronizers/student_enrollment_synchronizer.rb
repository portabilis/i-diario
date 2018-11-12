class StudentEnrollmentSynchronizer < BaseSynchronizer
  def synchronize!
    update_records api.fetch(ano: years.first, escola: unity_api_code)["matriculas"]

    finish_worker('StudentEnrollmentSynchronizer-' << years.first << '-' << unity_api_code)
  end

  protected

  def api
    IeducarApi::StudentEnrollments.new(synchronization.to_api)
  end

  def update_records(collection)
    if collection.present?
      updated_student_ids = []

      collection.each do |record|
        if student_enrollment = student_enrollments.find_by(api_code: record["matricula_id"])
          update_existing_student_enrollment(record, student_enrollment, updated_student_ids)
        else
          create_new_student_enrollment(record, updated_student_ids)
        end
      end

      updated_student_ids.uniq.each do |student_id|
        classroom_ids = StudentEnrollmentClassroom.unscoped
          .by_student(student_id)
          .pluck(:classroom_id)
          .compact
          .uniq

        classroom_ids.each do |classroom_id|
          DeleteInvalidPresenceRecordWorker.perform_async(entity_id, student_id, classroom_id)
        end
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
      api_code: record["matricula_id"],
      status: record["situacao"],
      student_id: student_id(record),
      student_code: record["aluno_id"],
      changed_at: record["data_atualizacao"].to_s,
      active: record["ativo"]
    )

    if record["enturmacoes"].present?
      record["enturmacoes"].each do |record_classroom|
        student_enrollment.student_enrollment_classrooms.create!(
          api_code: record_classroom["sequencial"],
          classroom_id: Classroom.find_by(api_code: record_classroom["turma_id"]).try(:id),
          classroom_code: record_classroom["turma_id"],
          joined_at: record_classroom["data_entrada"],
          left_at: record_classroom["data_saida"],
          changed_at: record_classroom["data_atualizacao"].to_s,
          sequence: record_classroom["sequencial_fechamento"],
          show_as_inactive_when_not_in_date: record_classroom["apresentar_fora_da_data"],
          visible: record_classroom["mostrar_enturmacao"]
        )
      end
    end
  end

  def update_existing_student_enrollment(record, student_enrollment, updated_student_ids)
    return unless student_id(record)

    if record["data_atualizacao"].blank? ||
        student_enrollment.changed_at.blank? ||
        record["data_atualizacao"].to_s > student_enrollment.changed_at.to_s
      student_enrollment.update(
        status: record["situacao"],
        student_id: student_id(record),
        student_code: record["aluno_id"],
        changed_at: record["data_atualizacao"].to_s,
        active: record["ativo"]
      )
    end

    if record["enturmacoes"].present?
      updated_student_ids << student_id(record)
      any_updated_or_new_record = false

      record["enturmacoes"].each do |record_classroom|
        if student_enrollment_classroom = student_enrollment.student_enrollment_classrooms.find_by(api_code: record_classroom["sequencial"])
          any_updated_or_new_record = record_classroom["data_atualizacao"].blank? ||
            record_classroom["data_atualizacao"].to_s > student_enrollment_classroom.changed_at.to_s
          break if any_updated_or_new_record
        else
          any_updated_or_new_record = true
          break
        end
      end

      if any_updated_or_new_record
        ActiveRecord::Base.transaction do
          student_enrollment.student_enrollment_classrooms.destroy_all

          record["enturmacoes"].each do |record_classroom|
            student_enrollment.student_enrollment_classrooms.create!(
              api_code: record_classroom["sequencial"],
              classroom_id: Classroom.find_by(api_code: record_classroom["turma_id"]).try(:id),
              classroom_code: record_classroom["turma_id"],
              joined_at: record_classroom["data_entrada"],
              left_at: record_classroom["data_saida"],
              changed_at: record_classroom["data_atualizacao"].to_s,
              sequence: record_classroom["sequencial_fechamento"],
              show_as_inactive_when_not_in_date: record_classroom["apresentar_fora_da_data"],
              visible: record_classroom["mostrar_enturmacao"]
            )
          end
        end
      else
        record["enturmacoes"].each do |record_classroom|
          if !student_enrollment.student_enrollment_classrooms.find_by(api_code: record_classroom["sequencial"])
            student_enrollment.student_enrollment_classrooms.create!(
              api_code: record_classroom["sequencial"],
              classroom_id: Classroom.find_by(api_code: record_classroom["turma_id"]).try(:id),
              classroom_code: record_classroom["turma_id"],
              joined_at: record_classroom["data_entrada"],
              left_at: record_classroom["data_saida"],
              changed_at: record_classroom["data_atualizacao"].to_s,
              sequence: record_classroom["sequencial_fechamento"],
              show_as_inactive_when_not_in_date: record_classroom["apresentar_fora_da_data"],
              visible: record_classroom["mostrar_enturmacao"]
            )
          end
        end
      end
    end
  end

  private

  def student_id(record)
    @student_ids ||= {}
    @student_ids[record["aluno_id"]] ||= Student.find_by(api_code: record["aluno_id"]).try(:id)
  end
end
