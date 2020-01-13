class SchoolCalendarsSynchronizer < BaseSynchronizer
  DEFAULT_NUMBER_OF_CLASSES = 4

  def synchronize!
    update_school_calendars(
      HashDecorator.new(
        api.fetch(
          escola: unity_api_code,
          classroom_steps: false
        )['escolas']
      )
    )
  end

  private

  def api_class
    IeducarApi::SchoolCalendars
  end

  def update_school_calendars(school_calendars)
    school_calendars.each do |school_calendar_record|
      unity_id = unity(school_calendar_record.escola_id).try(&:id)

      next if unity_id.blank?

      finded_school_calendar = SchoolCalendar.find_by(unity_id: unity_id, year: school_calendar_record.ano)

      next if !school_calendar_record.ano_em_aberto &&
              (finded_school_calendar.blank? || !finded_school_calendar.opened_year)

      (finded_school_calendar || SchoolCalendar.new(
        unity_id: unity_id,
        year: school_calendar_record.ano
      )).tap do |school_calendar|
        school_calendar.number_of_classes = DEFAULT_NUMBER_OF_CLASSES if school_calendar.new_record?
        school_calendar.step_type_description = school_calendar_record.descricao
        school_calendar.opened_year = school_calendar_record.ano_em_aberto

        school_calendar.save! if school_calendar.changed?

        @school_calendar_steps_ids = []
        school_calendar_id = school_calendar.id

        update_or_create_steps(school_calendar_record.etapas, school_calendar_id)

        destroy_removed_steps(school_calendar_id)

        unless school_calendar.opened_year
          remove_closed_years_on_selected_profiles(school_calendar.unity_id, school_calendar.year)
        end
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

        if school_calendar_step.new_record?
          school_calendar_step.start_date_for_posting = school_calendar_steps_record.data_inicio
          school_calendar_step.end_date_for_posting = school_calendar_steps_record.data_fim
        end

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

  def remove_closed_years_on_selected_profiles(unity_id, year)
    RemoveClosedYearsOnSelectedProfilesWorker.perform_in(
      1.second,
      entity_id,
      unity_id,
      year
    )
  end
end
