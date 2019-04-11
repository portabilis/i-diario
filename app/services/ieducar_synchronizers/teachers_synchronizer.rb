class TeachersSynchronizer < BaseSynchronizer
  def synchronize!
    years.each do |year|
      update_records(
        HashDecorator.new(
          api.fetch(ano: year)['servidores']
        ),
        year
      )
    end
  end

  private

  def api
    @api = api_class.new(synchronization.to_api, true)
  end

  def api_class
    IeducarApi::Teachers
  end

  def update_records(teachers, year)
    ActiveRecord::Base.transaction do
      existing_ids = []

      teachers.each do |teacher_record|
        existing_ids << teacher_record.id
        teacher = create_or_update_teacher(teacher_record)

        next if teacher.blank?

        discipline_classrooms = teacher_record.disciplinas_turmas

        create_or_update_teacher_discipline_classrooms(teacher, teacher_record, discipline_classrooms, year)
      end

      discard_inexisting_teacher_discipline_classrooms(year, existing_ids)
    end
  end

  def create_or_update_teacher_discipline_classrooms(teacher, teacher_record, discipline_classrooms, year)
    discipline_classrooms.each do |discipline_classroom|
      TeacherDisciplineClassroom.unscoped.find_or_initialize_by(
        api_code: teacher_record.id,
        year: year,
        active: true,
        teacher_id: teacher.id,
        teacher_api_code: teacher.api_code,
        discipline_id: discipline(discipline_classroom.disciplina_id).try(:id),
        discipline_api_code: discipline_classroom.disciplina_id,
        classroom_id: classroom(discipline_classroom.turma_id).try(:id),
        classroom_api_code: discipline_classroom.turma_id
      ).tap do |teacher_discipline_classroom|
        teacher_discipline_classroom.allow_absence_by_discipline =
          discipline_classroom.permite_lancar_faltas_componente
        teacher_discipline_classroom.changed_at = teacher_record.updated_at
        teacher_discipline_classroom.period = teacher_record.turno_id
        teacher_discipline_classroom.score_type = discipline_classroom.tipo_nota
        teacher_discipline_classroom.save! if teacher_discipline_classroom.changed?
      end
    end
  end

  def create_or_update_teacher(teacher_record)
    Teacher.with_discarded.find_or_initialize_by(api_code: teacher_record.id).tap do |teacher|
      teacher.name = teacher_record.name
      teacher.active = teacher_record.ativo == IeducarBooleanState::ACTIVE
      teacher.save! if teacher.changed?

      teacher.discard_or_undiscard(teacher_record.deleted_at.present?)
    end
  end

  def discard_inexisting_teacher_discipline_classrooms(year, existing_ids)
    teacher_discipline_classrooms_to_discard(year, existing_ids).each do |teacher_discipline_classroom|
      teacher_discipline_classroom.discard_or_undiscard(true)
    end
  end

  def teacher_discipline_classrooms_to_discard(year, existing_ids)
    TeacherDisciplineClassroom.unscoped
                              .where(year: year)
                              .where.not(api_code: existing_ids)
  end
end
