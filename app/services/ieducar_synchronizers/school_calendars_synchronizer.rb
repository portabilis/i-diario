class SchoolCalendarsSynchronizer < BaseSynchronizer
  DEFAULT_NUMBER_OF_CLASSES = 4

  def synchronize!
    update_school_calendars(
      HashDecorator.new(
        api.fetch['escolas']
      )
    )
  end

  private

  def api_class
    IeducarApi::SchoolCalendars
  end

  def update_school_calendars(school_calendars)
    school_calendars.each do |school_calendar_record|
      next unless school_calendar_record.ano_em_aberto

      unity_id = unity(school_calendar_record.escola_id).try(&:id)

      next if unity_id.blank?

      SchoolCalendar.find_or_initialize_by(
        unity_id: unity_id,
        year: school_calendar_record.ano
      ).tap do |school_calendar|
        school_calendar.number_of_classes = DEFAULT_NUMBER_OF_CLASSES
        school_calendar.step_type_description = school_calendar_record.descricao

        school_calendar.save! if school_calendar.changed?

        @school_calendar_steps_ids = []
        school_calendar_id = school_calendar.id

        update_or_create_steps(school_calendar_record.etapas, school_calendar_id)

        destroy_removed_steps(school_calendar_id)
      end
    end
  end

  def update_or_create_steps(school_calendar_steps, school_calendar_id)
    school_calendar_steps.each do |school_calendar_steps_record|
      SchoolCalendarStep.find_or_initialize_by(
        school_calendar_id: school_calendar_id,
        step_number: school_calendar_steps_record.etapa
      ).tap do |school_calendar_step|
        school_calendar_step.start_at = school_calendar_steps_record.data_inicio
        school_calendar_step.end_at = school_calendar_steps_record.data_fim
        school_calendar_step.start_date_for_posting = school_calendar_steps_record.data_fim
        school_calendar_step.end_date_for_posting = school_calendar_steps_record.data_fim

        school_calendar_step.save! if school_calendar_step.changed?

        @school_calendar_steps_ids << school_calendar_step.id
      end
    end
  end

  def destroy_removed_steps(school_calendar_id)
    SchoolCalendarStep.where(school_calendar_id: school_calendar_id)
                      .where.not(id: @school_calendar_steps_ids)
                      .destroy_all
  end
end
