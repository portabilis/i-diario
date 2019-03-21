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

  protected

  def api_class
    IeducarApi::Teachers
  end

  def update_records(discipline_classrooms, year)
    ActiveRecord::Base.transaction do
      update_discipline_classrooms(discipline_classrooms, year)
    end
  end

  def update_discipline_classrooms(discipline_classrooms, year)
    existing_ids = []

    discipline_classrooms.each do |discipline_classroom_record|
      existing_ids << discipline_classroom_record.id
      teacher = update_teacher(discipline_classroom_record)

      next unless teacher

      teacher_discipline_classrooms = TeacherDisciplineClassroom.unscoped.where(
        api_code: discipline_classroom_record.id
      )

      max_changed_at = teacher_discipline_classrooms.maximum(:changed_at)
      discipline_classrooms = discipline_classroom_record.disciplinas_turmas

      if !max_changed_at ||
         discipline_classroom_record.updated_at > max_changed_at ||
         teacher_discipline_classrooms.count != discipline_classrooms.count
        teacher_discipline_classrooms.destroy_all
        create_discipline_classrooms(discipline_classroom_record, year, teacher)
      end

      discipline_classrooms.each do |discipline_classroom|
        next if discipline_classroom.tipo_nota.nil?

        teacher_discipline_classroom = TeacherDisciplineClassroom.find_by(
          teacher_api_code: discipline_classroom_record.servidor_id,
          discipline_api_code: discipline_classroom.disciplina_id,
          api_code: discipline_classroom_record.id
        )

        binding.pry if teacher_discipline_classroom.blank?

        teacher_discipline_classroom.update!(score_type: discipline_classroom.tipo_nota)
      end
    end

    destroy_inexisting_teacher_discipline_classrooms(year, existing_ids)
  end

  private

  def destroy_inexisting_teacher_discipline_classrooms(year, existing_ids)
    TeacherDisciplineClassroom.where(year: year)
                              .where.not(api_code: existing_ids)
                              .destroy_all
  end

  def create_discipline_classrooms(discipline_classroom_record, year, teacher)
    discipline_classroom_record.disciplinas_turmas.each do |discipline_classroom|
      TeacherDisciplineClassroom.create!(
        api_code: discipline_classroom_record.id,
        year: year,
        active: true,
        teacher_id: teacher.id,
        teacher_api_code: teacher.api_code,
        discipline_id: Discipline.find_by(api_code: discipline_classroom.disciplina_id).try(:id),
        discipline_api_code: discipline_classroom.disciplina_id,
        classroom_id: Classroom.find_by(api_code: discipline_classroom.turma_id).try(:id),
        classroom_api_code: discipline_classroom.turma_id,
        allow_absence_by_discipline: discipline_classroom.permite_lancar_faltas_componente,
        changed_at: discipline_classroom_record.updated_at,
        period: discipline_classroom_record.turno_id
      )
    end
  end

  def update_teacher(teacher_record)
    Teacher.find_or_initialize_by(api_code: teacher_record.id).tap do |teacher|
      teacher.name = teacher_record.name
      teacher.active = teacher_record.ativo == IeducarBooleanState::ACTIVE
      teacher.save! if teacher.changed?

      teacher.discard_or_undiscard(teacher_record.deleted_at.present?)
    end
  end

  def inactive_all_alocations_prior_to(year)
    TeacherDisciplineClassroom.unscoped
                              .where('year < ?', year)
                              .destroy_all
  end
end
