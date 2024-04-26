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
  rescue IeducarApi::Base::ApiError => error
    synchronization.mark_as_error!(error.message)
  end

  private

  attr_accessor :reversed

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

        begin
          SchoolCalendarClassroom.find_or_initialize_by(
            classroom_id: classroom_id
          ).tap do |school_calendar_classroom|
            school_calendar_classroom.step_type_description = school_calendar_classroom_record.descricao
            school_calendar_classroom.school_calendar_id = school_calendar.id

            school_calendar_classroom.save! if school_calendar_classroom.changed?

            @school_calendar_classroom_steps_ids = []
            school_calendar_classroom_id = school_calendar_classroom.id

            update_or_create_steps(school_calendar_classroom_record.etapas, school_calendar_classroom_id)

            destroy_removed_steps(school_calendar_classroom_id)

            update_or_create_school_term_types(school_calendar_classroom)
          end
        rescue ActiveRecord::RecordInvalid => error
          known_error_messages = [
            I18n.t('ieducar_api.error.messages.must_be_less_than_end_at')
          ]

          raise error unless known_error_messages.any? { |known_error| error.message.include?(known_error) }

          mark_with_error(error)
        end

        remove_school_calendar_classrooms(school_calendar, school_calendar_record)
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

  def update_or_create_steps(school_calendar_classroom_record_steps, school_calendar_classroom_id)
    school_calendar_classroom_record_steps.each do |school_calendar_classroom_step_record|
      SchoolCalendarClassroomStep.find_or_initialize_by(
        school_calendar_classroom_id: school_calendar_classroom_id,
        step_number: school_calendar_classroom_step_record.etapa
      ).tap do |school_calendar_classroom_step|
        start_at = school_calendar_classroom_step_record.data_inicio.to_date
        end_at = school_calendar_classroom_step_record.data_fim.to_date
        school_calendar_classroom_step.start_at = start_at
        school_calendar_classroom_step.end_at = end_at

        new_record = school_calendar_classroom_step.new_record?

        if new_record || school_calendar_classroom_step.start_date_for_posting < start_at
          school_calendar_classroom_step.start_date_for_posting = start_at
        end

        start_date_for_posting = school_calendar_classroom_step.start_date_for_posting
        end_date_for_posting = school_calendar_classroom_step.end_date_for_posting

        if new_record || end_date_for_posting < start_at || end_date_for_posting < start_date_for_posting
          school_calendar_classroom_step.end_date_for_posting = end_at
        end

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

  def mark_with_error(error)
    unity ||= error.record&.school_calendar&.unity
    unity = "Escola: #{unity.api_code} - #{unity.name}" if unity.present?
    classroom ||= error.record&.classroom
    classroom = "Turma: #{classroom.api_code} - #{classroom.description}" if classroom.present?
    error_message = "#{unity}, #{classroom}: #{error.message}"

    worker_state.add_error!(error_message)
  end

  def update_or_create_school_term_types(school_calendar_classroom)
    SchoolTermTypeUpdaterWorker.perform_in(
      1.second,
      entity_id,
      nil,
      school_calendar_classroom.id
    )
  end

  def remove_school_calendar_classrooms(school_calendar, school_calendar_record)
    school_calendar_classrooms = SchoolCalendarClassroom
      .joins(:classroom)
      .where(school_calendar_id: school_calendar.id)

    school_calendar_classrooms.each do |school_calendar_classroom|
      api_code = school_calendar_classroom.classroom.api_code.to_i

      next if school_calendar_record.etapas_de_turmas.map(&:turma_id).include?(api_code)

      school_calendar_classroom.destroy
    end
  end
end
