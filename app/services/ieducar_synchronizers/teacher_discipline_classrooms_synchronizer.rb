class TeacherDisciplineClassroomsSynchronizer < BaseSynchronizer
  def synchronize!
    update_teacher_discipline_classrooms(
      HashDecorator.new(
        api.fetch(
          ano: year,
          escola: unity_api_code
        )['vinculos']
      )
    )
  end

  private

  def api_class
    IeducarApi::TeacherDisciplineClassrooms
  end

  def update_teacher_discipline_classrooms(teacher_discipline_classrooms)
    ActiveRecord::Base.transaction do
      teacher_discipline_classrooms.each do |teacher_discipline_classroom_record|
        existing_discipline_api_codes = []

        (teacher_discipline_classroom_record.disciplinas || []).each do |discipline_by_score_type|
          discipline_api_code, score_type = discipline_by_score_type.split
          existing_discipline_api_codes << discipline_api_code

          create_or_update_teacher_discipline_classrooms(
            teacher_discipline_classroom_record,
            discipline_api_code,
            score_type
          )
        end

        discard_inexisting_teacher_discipline_classrooms(
          teacher_discipline_classrooms_to_discard(
            teacher_discipline_classroom_record,
            existing_discipline_api_codes
          )
        )

        create_empty_conceptual_exam_value(teacher_discipline_classroom_record)
      end
    end
  end

  def create_or_update_teacher_discipline_classrooms(
    teacher_discipline_classroom_record,
    discipline_api_code,
    score_type
  )
    teacher_id = teacher(teacher_discipline_classroom_record.servidor_id).try(:id)

    return if teacher_id.blank?

    classroom_id = classroom(teacher_discipline_classroom_record.turma_id).try(:id)

    return if classroom_id.blank?

    discipline_id = discipline(discipline_api_code).try(:id)

    return if discipline_id.blank?

    teacher_discipline_classrooms = TeacherDisciplineClassroom.unscoped.where(
      api_code: teacher_discipline_classroom_record.id,
      year: year,
      teacher_id: teacher_id,
      teacher_api_code: teacher_discipline_classroom_record.servidor_id,
      discipline_id: discipline_id,
      discipline_api_code: discipline_api_code
    )

    teacher_discipline_classroom =
      if teacher_discipline_classrooms.size == 1
        teacher_discipline_classrooms.first
      elsif teacher_discipline_classrooms.size > 1
        teacher_discipline_classrooms.find_by(discarded_at: nil)
      end

    teacher_discipline_classroom ||= TeacherDisciplineClassroom.new(
      api_code: teacher_discipline_classroom_record.id,
      year: year,
      teacher_id: teacher_id,
      teacher_api_code: teacher_discipline_classroom_record.servidor_id,
      discipline_id: discipline_id,
      discipline_api_code: discipline_api_code
    )

    teacher_discipline_classroom.classroom_id = classroom_id
    teacher_discipline_classroom.classroom_api_code = teacher_discipline_classroom_record.turma_id
    teacher_discipline_classroom.allow_absence_by_discipline =
      teacher_discipline_classroom_record.permite_lancar_faltas_componente
    teacher_discipline_classroom.changed_at = teacher_discipline_classroom_record.updated_at
    teacher_discipline_classroom.period = teacher_discipline_classroom_record.turno_id
    teacher_discipline_classroom.score_type = score_type
    teacher_discipline_classroom.active = true if teacher_discipline_classroom.active.nil?
    teacher_discipline_classroom.save! if teacher_discipline_classroom.changed?

    teacher_discipline_classroom.discard_or_undiscard(false)
  end

  def discard_inexisting_teacher_discipline_classrooms(teacher_discipline_classrooms_to_discard)
    teacher_discipline_classrooms_to_discard.each do |teacher_discipline_classroom|
      teacher_discipline_classroom.discard_or_undiscard(true)
    end
  end

  def teacher_discipline_classrooms_to_discard(teacher_discipline_classroom_record, existing_discipline_api_codes)
    teacher_discipline_classrooms = TeacherDisciplineClassroom.unscoped.where(
      api_code: teacher_discipline_classroom_record.id
    )

    return teacher_discipline_classrooms if teacher_discipline_classroom_record.deleted_at.present?

    teacher_discipline_classrooms.where.not(discipline_api_code: existing_discipline_api_codes)
  end

  def create_empty_conceptual_exam_value(teacher_discipline_classroom_record)
    classroom = classroom(teacher_discipline_classroom_record.turma_id)
    classroom_id = classroom.try(:id)

    teacher_id = teacher(teacher_discipline_classroom_record.servidor_id).try(:id)

    return if teacher_id.nil?
    return if classroom_id.nil?
    return if classroom.discarded?

    CreateEmptyConceptualExamValueWorker.perform_in(
      1.second,
      entity_id,
      classroom_id,
      teacher_id
    )
  end
end
