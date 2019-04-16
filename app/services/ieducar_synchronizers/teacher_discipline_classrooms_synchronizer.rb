class TeacherDisciplineClassroomsSynchronizer < BaseSynchronizer
  def synchronize!
    update_teacher_discipline_classrooms(
      HashDecorator.new(
        api.fetch(
          ano: years.first
        )['vinculos']
      )
    )
  end

  def self.synchronize_in_batch!(params)
    super do
      params[:years].each do |year|
        new(
          synchronization: params[:synchronization],
          worker_batch: params[:worker_batch],
          years: [year],
          entity_id: params[:entity_id]
        ).synchronize!
      end
    end
  end

  private

  def api_class
    IeducarApi::TeacherDisciplineClassrooms
  end

  def update_teacher_discipline_classrooms(teacher_discipline_classrooms)
    ActiveRecord::Base.transaction do
      teacher_discipline_classrooms.each do |teacher_discipline_classroom_record|
        existing_discipline_api_codes = []

        (teacher_discipline_classroom_record.disciplinas || []).each do |discipline_api_code|
          existing_discipline_api_codes << discipline_api_code

          create_or_update_teacher_discipline_classrooms(teacher_discipline_classroom_record, discipline_api_code)
        end

        discard_inexisting_teacher_discipline_classrooms(
          teacher_discipline_classroom_record.id,
          existing_discipline_api_codes
        )
      end
    end
  end

  def create_or_update_teacher_discipline_classrooms(teacher_discipline_classroom_record, discipline_api_code)
    TeacherDisciplineClassroom.unscoped.find_or_initialize_by(
      api_code: teacher_discipline_classroom_record.id,
      year: years.first,
      teacher_id: teacher(teacher_discipline_classroom_record.servidor_id).try(:id),
      teacher_api_code: teacher_discipline_classroom_record.servidor_id,
      discipline_id: discipline(discipline_api_code).try(:id),
      discipline_api_code: discipline_api_code,
      classroom_id: classroom(teacher_discipline_classroom_record.turma_id).try(:id),
      classroom_api_code: teacher_discipline_classroom_record.turma_id
    ).tap do |teacher_discipline_classroom|
      teacher_discipline_classroom.allow_absence_by_discipline =
        teacher_discipline_classroom_record.permite_lancar_faltas_componente
      teacher_discipline_classroom.changed_at = teacher_discipline_classroom_record.updated_at
      teacher_discipline_classroom.period = teacher_discipline_classroom_record.turno_id
      teacher_discipline_classroom.score_type = teacher_discipline_classroom_record.tipo_nota
      teacher_discipline_classroom.active = true if teacher_discipline_classroom.active.nil?
      teacher_discipline_classroom.save! if teacher_discipline_classroom.changed?

      teacher_discipline_classroom.discard_or_undiscard(teacher_discipline_classroom_record.deleted_at.present?)
    end
  end

  def discard_inexisting_teacher_discipline_classrooms(api_code, existing_discipline_api_codes)
    teacher_discipline_classrooms_to_discard(
      api_code,
      existing_discipline_api_codes
    ).each do |teacher_discipline_classroom|
      teacher_discipline_classroom.discard_or_undiscard(true)
    end
  end

  def teacher_discipline_classrooms_to_discard(api_code, existing_discipline_api_codes)
    TeacherDisciplineClassroom.unscoped
                              .where(api_code: api_code)
                              .where.not(discipline_api_code: existing_discipline_api_codes)
  end
end
