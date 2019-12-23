class SchoolCalendarClassroomsSynchronizer < BaseSynchronizer
  def synchronize!
    update_school_calendar_classrooms(
      HashDecorator.new(
        api.fetch(
          escola: unity_api_code,
          ano: year,
          classroom_steps: true
        )['escolas']
      )
    )
  end

  private

  def api_class
    IeducarApi::SchoolCalendars
  end

  def update_school_calendar_classrooms(school_calendars)
    school_calendars.each do |school_calendar_record|
      next unless school_calendar_record.ano_em_aberto

      unity_id = unity(school_calendar_record.escola_id).try(&:id)

      next if unity_id.blank?

      school_calendar = SchoolCalendar.find_by(
        year: school_calendar_record.ano,
        unity_id: unity_id
      )

      next if school_calendar.blank?

      school_calendar_record.etapas_de_turmas.each do |school_calendar_classroom_record|
        classroom_id = classroom(school_calendar_classroom_record.turma_id).try(&:id)

        next if classroom_id.blank?

        SchoolCalendarClassroom.find_or_initialize_by(
          classroom_id: classroom_id,
          school_calendar_id: school_calendar.id
        ).tap do |school_calendar_classroom|
          school_calendar_classroom.step_type_description = school_calendar_classroom_record.descricao

          school_calendar_classroom.save! if school_calendar_classroom.changed?

          @school_calendar_classroom_steps_ids = []
          school_calendar_classroom_id = school_calendar_classroom.id

          update_or_create_steps(school_calendar_classroom_record.etapas, school_calendar_classroom_id)

          destroy_removed_steps(school_calendar_classroom_id)
        end
      end
    end
  end

  def update_or_create_steps(school_calendar_classroom_record_steps, school_calendar_classroom_id)
    school_calendar_classroom_record_steps.each do |school_calendar_classroom_step_record|
      SchoolCalendarClassroomStep.find_or_initialize_by(
        school_calendar_classroom_id: school_calendar_classroom_id,
        step_number: school_calendar_classroom_step_record.etapa
      ).tap do |school_calendar_classroom_step|
        school_calendar_classroom_step.start_at = school_calendar_classroom_step_record.data_inicio
        school_calendar_classroom_step.end_at = school_calendar_classroom_step_record.data_fim
        school_calendar_classroom_step.start_date_for_posting =
          school_calendar_classroom_step_record.data_inicio
        school_calendar_classroom_step.end_date_for_posting = school_calendar_classroom_step_record.data_fim

        school_calendar_classroom_step.save! if school_calendar_classroom_step.changed?

        @school_calendar_classroom_steps_ids << school_calendar_classroom_step.id
      end
    end
  end

  def destroy_removed_steps(school_calendar_classroom_id)
    SchoolCalendarClassroomStep.where(school_calendar_classroom_id: school_calendar_classroom_id)
                               .where.not(id: @school_calendar_classroom_steps_ids)
                               .destroy_all
  end
end
