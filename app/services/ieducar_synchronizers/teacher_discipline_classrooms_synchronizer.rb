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
  rescue IeducarApi::Base::ApiError => error
    synchronization.mark_as_error!(error.message)
  end

  private

  def api_class
    IeducarApi::TeacherDisciplineClassrooms
  end

  def update_teacher_discipline_classrooms(teacher_discipline_classrooms)
    ActiveRecord::Base.transaction do
      teacher_discipline_classrooms.each do |teacher_discipline_classroom_record|
        existing_discipline_api_codes = []
        created_linked_teachers = []

        classroom = classroom(teacher_discipline_classroom_record.turma_id)
        teacher = teacher(teacher_discipline_classroom_record.servidor_id)

        if classroom.blank? || teacher.blank? || classroom.discarded? || teacher.discarded?
          TeacherDisciplineClassroom.unscoped.where(
            api_code: teacher_discipline_classroom_record.id,
            year: year
          ).each(&:discard)
          next
        end

        teacher_id = teacher.try(:id)
        classroom_id = classroom.try(:id)

        teacher_discipline_classroom_record.disciplinas.each do |discipline_by_grade|
          discipline_api_code = discipline_by_grade.id
          score_type = discipline_by_grade.tipo_nota
          grade_api_code = discipline_by_grade.serie_id

          existing_discipline_api_codes << discipline_api_code

          created_linked_teachers << create_or_update_teacher_discipline_classrooms(
            teacher_discipline_classroom_record,
            classroom_id,
            teacher_id,
            discipline_api_code,
            grade_api_code,
            score_type
          )

          if teacher_discipline_classroom_record.deleted_at.blank?
            create_empty_conceptual_exam_value(discipline_by_grade, classroom_id, teacher_id)
          end
        end

        links_fake_disciplines = teacher_discipline_classroom_record if teacher_discipline_classroom_record.disciplinas.blank?

        create_or_destroy_teacher_disciplines_classrooms(created_linked_teachers, teacher_id, classroom_id, links_fake_disciplines)

        discard_inexisting_teacher_discipline_classrooms(
          teacher_discipline_classrooms_to_discard(
            teacher_discipline_classroom_record,
            existing_discipline_api_codes
          )
        )
      end
    end
  end

  def create_or_update_teacher_discipline_classrooms(
    teacher_discipline_classroom_record,
    classroom_id,
    teacher_id,
    discipline_api_code,
    grade_api_code,
    score_type
  )
    discipline_id = discipline(discipline_api_code).try(:id)

    return if discipline_id.blank?

    grade_id = grade(grade_api_code).try(:id)

    return if grade_id.blank?

    teacher_discipline_classrooms = TeacherDisciplineClassroom.unscoped.where(
      api_code: teacher_discipline_classroom_record.id,
      year: year,
      discipline_id: discipline_id,
      teacher_id: teacher_id,
      grade_id: grade_id,
      classroom_id: classroom_id
    )

    if teacher_discipline_classrooms.blank?
      # Busca os vinculos que nao pertencem mais a turma (cenario de edicao no iEducar)
      link_modifiers = TeacherDisciplineClassroom.unscoped.where(
        api_code: teacher_discipline_classroom_record.id
      ).where.not(classroom_id: classroom_id).each(&:discard)

      # Verifica se existe + vinculos de disciplinas agrupadoras e descarta os vinculos
      classroom_old = link_modifiers.map(&:classroom_id).uniq
      destroy_grouped_links(classroom_old, teacher_id)
    end

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
      grade_id: grade_id,
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

    if teacher_discipline_classroom.new_record?
      cache_key = "last_teacher_discipline_classroom-#{classroom_id}-#{teacher_id}"
      Rails.cache.delete(cache_key)
    end

    teacher_discipline_classroom.discard_or_undiscard(false)

    teacher_discipline_classroom
  end

  def discard_inexisting_teacher_discipline_classrooms(teacher_discipline_classrooms_to_discard)
    teacher_discipline_classrooms_to_discard.each do |teacher_discipline_classroom|
      teacher_discipline_classroom.discard_or_undiscard(true)
    end
  end

  def teacher_discipline_classrooms_to_discard(teacher_discipline_classroom_record, existing_discipline_api_codes)
    teacher_discipline_classrooms = TeacherDisciplineClassroom.unscoped.where(
      api_code: teacher_discipline_classroom_record.id,
      year: year
    )

    existing_disciplines_ids = Discipline.where(api_code: existing_discipline_api_codes).pluck(:id)

    return teacher_discipline_classrooms if teacher_discipline_classroom_record.deleted_at.present?

    teacher_discipline_classrooms.where.not(discipline_id: existing_disciplines_ids)
  end

  def create_empty_conceptual_exam_value(discipline_by_grade, classroom_id, teacher_id)
    discipline_id = discipline(discipline_by_grade.id).try(:id)
    grade_id = grade(discipline_by_grade.serie_id).try(:id)

    return if grade_id.nil?
    return if discipline_id.nil?

    CreateEmptyConceptualExamValueWorker.perform_in(
      1.second,
      entity_id,
      classroom_id,
      teacher_id,
      grade_id,
      discipline_id
    )
  end

  def create_or_destroy_teacher_disciplines_classrooms(
    linked_teachers,
    teacher_id,
    classroom_id,
    links_fake_disciplines = nil
  )
    if links_fake_disciplines.present? && links_fake_disciplines.deleted_at.present?
      link_fake = TeacherDisciplineClassroom.find_by(teacher_id: teacher_id, classroom_id: classroom_id)

      return if link_fake.nil?

      link_fake.api_code.include?('grouper') ? link_fake.discard : return
    end

    teacher_discipline_classrooms_ids = linked_teachers.map(&:id)

    TeacherDisciplineClassroom.includes(discipline: { knowledge_area: :disciplines })
                              .where(id: teacher_discipline_classrooms_ids)
                              .where(knowledge_areas: { group_descriptors: true })
                              .each do |teacher_discipline_classroom|
      fake_discipline = Discipline.unscoped.find_by(
        knowledge_area_id: teacher_discipline_classroom.knowledge_area.id,
        grouper: true
      )

      return if fake_discipline.nil?

      link_teacher = TeacherDisciplineClassroom.with_discarded.find_or_initialize_by(
        api_code: "grouper:#{fake_discipline.id}",
        year: year,
        teacher_id: teacher_discipline_classroom.teacher_id,
        teacher_api_code: teacher_discipline_classroom.teacher_api_code,
        grade_id: teacher_discipline_classroom.grade_id,
        discipline_id: fake_discipline.id,
        discipline_api_code: "grouper:#{fake_discipline.id}",
        classroom_id: teacher_discipline_classroom.classroom_id,
        classroom_api_code: "grouper:#{fake_discipline.id}"
      )

      link_teacher.assign_attributes(
        period: teacher_discipline_classroom.period,
        changed_at: teacher_discipline_classroom.changed_at
      )

      link_teacher.undiscard if link_teacher.discarded?

      link_teacher.save! if link_teacher.new_record? || link_teacher.changed?
    end
    destroy_grouped_links(classroom_id, teacher_id)
  end

  def destroy_grouped_links(classroom_id, teacher_id)
    grouped_link_id = GroupedTeacherDisciplineClassrooms.where(
      teacher_id: teacher_id,
      classroom_id: classroom_id
    ).map(&:link_id)

    TeacherDisciplineClassroom.where(id: grouped_link_id).each(&:destroy)
  end
end
