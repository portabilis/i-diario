class SchoolCalendarsSynchronizer < BaseSynchronizer
  DEFAULT_NUMBER_OF_CLASSES = 4
  YEARLY_SCHOOL_TERM_TYPE_DESCRIPTION = 'Anual'.freeze

  def synchronize!
    update_school_calendars(
      HashDecorator.new(
        api.fetch(
          escola: unity_api_code,
          classroom_steps: false
        )['escolas']
      )
    )
  rescue IeducarApi::Base::ApiError => error
    synchronization.mark_as_error!(error.message)
  end

  private

  attr_accessor :reversed

  def api_class
    IeducarApi::SchoolCalendars
  end

  def update_school_calendars(school_calendars)
    create_yearly_school_term_type

    school_calendars.each do |school_calendar_record|
      unity_id = unity(school_calendar_record.escola_id).try(&:id)

      next if unity_id.blank?

      found_school_calendar = SchoolCalendar.find_by(unity_id: unity_id, year: school_calendar_record.ano)

      next if !school_calendar_record.ano_em_aberto &&
              (found_school_calendar.blank? || !found_school_calendar.opened_year)

      begin
        (found_school_calendar || SchoolCalendar.new(
          unity_id: unity_id,
          year: school_calendar_record.ano
        )).tap do |school_calendar|
          school_calendar.number_of_classes = DEFAULT_NUMBER_OF_CLASSES if school_calendar.new_record?
          school_calendar.step_type_description = school_calendar_record.descricao
          school_calendar.opened_year = school_calendar_record.ano_em_aberto

          if school_calendar.changed?
            school_calendar.save!
            update_or_create_school_term_types(school_calendar)
          end

          @school_calendar_steps_ids = []
          @changed_steps = false
          @removed_steps = false
          school_calendar_id = school_calendar.id

          update_or_create_steps(school_calendar_record.etapas, school_calendar_id)

          destroy_removed_steps(school_calendar_id)

          if school_calendar.new_record? || @changed_steps || @removed_steps
            count_school_days(school_calendar)
            update_or_create_school_term_types(school_calendar)
          end

          unless school_calendar.opened_year
            remove_closed_years_on_selected_profiles(school_calendar.unity_id, school_calendar.year)
          end
        end
      rescue ActiveRecord::RecordInvalid => error
        known_error_messages = [
          I18n.t('ieducar_api.error.messages.must_be_less_than_end_at')
        ]

        raise error unless known_error_messages.any? { |known_error| error.message.include?(known_error) }

        mark_with_error(error)
      end
    end
  rescue ActiveRecord::RecordInvalid => error
    raise error if error.message.exclude?(I18n.t('ieducar_api.error.messages.must_not_have_conflicting_steps'))
    raise error if reversed

    # Isso e necessario para quando um calendario depender da alteracao da data da etapa de outro calendario
    school_calendars.reverse!
    @reversed = true
    retry
  end

  def update_or_create_steps(school_calendar_steps, school_calendar_id)
    school_calendar_steps.each do |school_calendar_steps_record|
      SchoolCalendarStep.find_or_initialize_by(
        school_calendar_id: school_calendar_id,
        step_number: school_calendar_steps_record.etapa
      ).tap do |school_calendar_step|
        start_at = school_calendar_steps_record.data_inicio.to_date
        end_at = school_calendar_steps_record.data_fim.to_date
        school_calendar_step.start_at = start_at
        school_calendar_step.end_at = end_at

        new_record = school_calendar_step.new_record?

        if new_record
          school_calendar_step.start_date_for_posting = start_at
          school_calendar_step.end_date_for_posting = end_at
        end

        if school_calendar_step.changed?
          school_calendar_step.save!
          @changed_steps = true
        end

        @school_calendar_steps_ids << school_calendar_step.id
      end
    end
  end

  def destroy_removed_steps(school_calendar_id)
    orphan_steps = SchoolCalendarStep.where(school_calendar_id: school_calendar_id)
                                     .where.not(id: @school_calendar_steps_ids)

    return if orphan_steps.empty?

    @removed_steps = true
    orphan_steps.destroy_all
  end

  def remove_closed_years_on_selected_profiles(unity_id, year)
    RemoveClosedYearsOnSelectedProfilesWorker.perform_in(
      1.second,
      entity_id,
      unity_id,
      year
    )
  end

  def count_school_days(school_calendar)
    SchoolDaysCounterWorker.perform_in(
      1.second,
      entity_id,
      school_calendar.id
    )
  end

  def mark_with_error(error)
    unity = error.record&.unity
    unity = "Escola: #{unity.api_code} - #{unity.name}" if unity.present?
    error_message = "#{unity}: #{error.message}"

    worker_state.add_error!(error_message)
  end

  def update_or_create_school_term_types(school_calendar)
    SchoolTermTypeUpdaterWorker.perform_in(
      1.second,
      entity_id,
      school_calendar.id,
      nil
    )
  end

  def create_yearly_school_term_type
    return if SchoolTermType.where(description: YEARLY_SCHOOL_TERM_TYPE_DESCRIPTION).exists?

    SchoolTermType.create!(description: YEARLY_SCHOOL_TERM_TYPE_DESCRIPTION, steps_number: 1)
  end
end
