class TeachersSynchronizer < BaseSynchronizer
  def synchronize!
    years.each do |year|
      update_records(api.fetch(ano: year)['servidores'], year)
    end
  end

  protected

  def api
    IeducarApi::Teachers.new(synchronization.to_api)
  end

  def update_records(collection, year)
    ActiveRecord::Base.transaction do
      update_discipline_classrooms(collection, year)
    end
  end

  def update_discipline_classrooms(collection, year)
    existing_ids = []

    collection.each do |record|
      existing_ids << record['id']
      teacher = update_or_create_teacher(record)
      next unless teacher

      teacher_discipline_classrooms = discipline_classrooms.unscoped.where(
        api_code: record['id']
      )

      max_changed_at = teacher_discipline_classrooms.maximum(:changed_at)
      discipline_classrooms = record['disciplinas_turmas']

      if !max_changed_at || record['updated_at'] > max_changed_at || teacher_discipline_classrooms.count != discipline_classrooms.count
        teacher_discipline_classrooms.destroy_all
        create_discipline_classrooms(record, year, teacher)
      end

      discipline_classrooms.each do |discipline_classroom|
        next if discipline_classroom['tipo_nota'].nil?

        teacher_discipline_classroom = TeacherDisciplineClassroom.find_by(
          teacher_api_code: record['servidor_id'],
          discipline_api_code: discipline_classroom['disciplina_id'],
          api_code: record['id']
        )
        teacher_discipline_classroom.update!(score_type: discipline_classroom['tipo_nota'])
      end
    end

    destroy_inexisting_teacher_discipline_classrooms(year, existing_ids)
  end

  private

  def destroy_inexisting_teacher_discipline_classrooms(year, existing_ids)
    discipline_classrooms.where(year: year).where.not(api_code: existing_ids).destroy_all
  end

  def create_discipline_classrooms(collection, year, teacher)
    collection['disciplinas_turmas'].each do |discipline_classroom|
      discipline_classrooms.create!(
        api_code: collection['id'],
        year: year,
        active: true,
        teacher_id: teacher.id,
        teacher_api_code: teacher.api_code,
        discipline_id: Discipline.find_by(api_code: discipline_classroom['disciplina_id']).try(:id),
        discipline_api_code: discipline_classroom['disciplina_id'],
        classroom_id: Classroom.find_by(api_code: discipline_classroom['turma_id']).try(:id),
        classroom_api_code: discipline_classroom['turma_id'],
        allow_absence_by_discipline: discipline_classroom['permite_lancar_faltas_componente'],
        changed_at: collection['updated_at'],
        period: collection['turno_id']
      )
    end
  end

  def teachers(klass = Teacher)
    klass
  end

  def discipline_classrooms(klass = TeacherDisciplineClassroom)
    klass
  end

  def update_or_create_teacher(record)
    teacher = teachers.find_by(api_code: record['servidor_id'])
    active = (record['ativo'] == IeducarBooleanState::ACTIVE)

    if teacher
      teacher.update_columns(
        name: record['name'],
        active: active
      )
    elsif record['name'].present?
      teacher = teachers.create!(
        api_code: record['servidor_id'],
        name: record['name'],
        active: active
      )
    end

    teacher
  end

  def inactive_all_alocations_prior_to(year)
    discipline_classrooms.unscoped.where('year < ?', year).destroy_all
  end
end
