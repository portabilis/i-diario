class DeficienciesSynchronizer < BaseSynchronizer
  def synchronize!
    update_deficiencies(
      HashDecorator.new(
        api.fetch(
          escola: unity_api_code
        )['deficiencias']
      )
    )
  rescue IeducarApi::Base::ApiError => error
    synchronization.mark_as_error!(error.message)
  end

  private

  attr_accessor :unity_id

  def api_class
    IeducarApi::Deficiencies
  end

  def update_deficiencies(deficiencies)
    unity_api_codes = unity_api_code.split(',')
    preload_unities(unity_api_codes)
    preload_students(deficiencies.flat_map(&:alunos))

    self.unity_id = unity_api_codes.map { |code| unity(code).try(:id) }

    deficiencies.each do |deficiency_record|
      Deficiency.with_discarded.find_or_initialize_by(api_code: deficiency_record.id).tap do |deficiency|
        deficiency.name = deficiency_record.nome
        deficiency.disconsider_differentiated_exam_rule = deficiency_record.desconsidera_regra_diferenciada
        changed = deficiency.changed?
        deficiency.save! if changed

        update_deficiency_students(deficiency.id, deficiency_record.alunos)

        deficiency.discard_or_undiscard(deficiency_record.deleted_at.present?)

        if changed
          update_students_uses_differentiated_exam_rule(
            deficiency_id: deficiency.id
          )
        end
      end
    end
  end

  def update_deficiency_students(deficiency_id, student_api_codes)
    student_ids = []

    student_api_codes.each do |student_api_code|
      student_id = student(student_api_code).try(:id)

      next if student_id.blank?

      student_ids << student_id

      sync_deficiency_student(deficiency_id, student_id)

      update_students_uses_differentiated_exam_rule(student_id: student_id)
    end

    discard_inexisting_deficiency_students(deficiency_id, student_ids)
  end

  # Cria ou reaproveita o vínculo do aluno com a deficiência e garante que fique ativo.
  def sync_deficiency_student(deficiency_id, student_id)
    retries = 0

    begin
      deficiency_student = existing_deficiency_student(deficiency_id, student_id) ||
                           DeficiencyStudent.new(deficiency_id: deficiency_id, student_id: student_id)

      deficiency_student.unity_id ||= target_unity_id(student_id)
      deficiency_student.save! if deficiency_student.changed?
      deficiency_student.discard_or_undiscard(false)
    rescue ActiveRecord::RecordNotUnique
      raise if (retries += 1) > MAX_RECORD_RETRIES

      retry
    end
  end

  # Procura o vínculo entre as escolas sincronizadas e também entre os sem escola, que são
  # reaproveitados em vez de virarem cópia. Prefere o candidato que já tem escola definida.
  def existing_deficiency_student(deficiency_id, student_id)
    DeficiencyStudent.with_discarded
                     .by_deficiency_id(deficiency_id)
                     .by_student_id(student_id)
                     .by_unity_id([unity_id, nil].flatten)
                     .order('unity_id IS NULL, id')
                     .first
  end

  # Escola a gravar no vínculo, sempre uma das consideradas na busca — do contrário o vínculo
  # não seria reencontrado e cada execução criaria uma cópia. Com várias escolas de uma vez,
  # usa a matrícula mais recente do aluno que esteja entre as sincronizadas.
  def target_unity_id(student_id)
    unity_ids = unity_id.compact

    return unity_ids.first if unity_ids.one?

    student_unities(student_id).find { |id| unity_ids.include?(id) }
  end

  def discard_inexisting_deficiency_students(deficiency_id, student_ids)
    deficiency_students_to_discard(deficiency_id, student_ids).each do |deficiency_student|
      deficiency_student.discard_or_undiscard(true)

      update_students_uses_differentiated_exam_rule(
        student_id: deficiency_student.student_id
      )
    end
  end

  def deficiency_students_to_discard(deficiency_id, student_ids)
    DeficiencyStudent.with_discarded
                     .by_deficiency_id(deficiency_id)
                     .by_unity_id([unity_id, nil].flatten)
                     .where.not(student_id: student_ids)
  end

  def update_students_uses_differentiated_exam_rule(deficiency_id: nil, student_id: nil)
    StudentsUpdateUsesDifferentiatedExamRuleWorker.perform_in(
      1.second,
      entity_id: entity_id,
      deficiency_id: deficiency_id,
      student_id: student_id,
      unity_id: unity_id
    )
  end

  def student_unities(student_id)
    Unity.joins(classrooms: [student_enrollment_classrooms: :student_enrollment])
         .where(student_enrollments: { student_id: student_id, active: 1 })
         .order('student_enrollment_classrooms.joined_at desc')
         .ids
         .uniq
  end
end
