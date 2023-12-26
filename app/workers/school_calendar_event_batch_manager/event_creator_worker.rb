module SchoolCalendarEventBatchManager
  class EventCreatorWorker < Base
    class EventsNotCreatedError < StandardError; end

    def perform(entity_id, school_calendar_event_batch_id, user_id, action_name)
      Entity.find(entity_id).using_connection do
        begin
          school_calendar_event_batch = SchoolCalendarEventBatch.find(school_calendar_event_batch_id)
          created = false

          SchoolCalendar.by_year(school_calendar_event_batch.year).each do |school_calendar|
            begin
              SchoolCalendarEvent.find_or_initialize_by(
                school_calendar_id: school_calendar.id,
                batch_id: school_calendar_event_batch.id
              ).tap do |event|
                event.description = school_calendar_event_batch.description
                event.start_date = school_calendar_event_batch.start_date
                event.end_date = school_calendar_event_batch.end_date
                event.event_type = school_calendar_event_batch.event_type
                event.periods = school_calendar_event_batch.periods
                event.legend = school_calendar_event_batch.legend
                event.show_in_frequency_record = school_calendar_event_batch.show_in_frequency_record
                event.save! if event.changed?

                created = true

                school_calendars_days(school_calendar_event_batch, action_name)
              end
            rescue ActiveRecord::RecordInvalid
              unity_name = Unity.find_by(id: school_calendar.unity_id)&.name

              school_calendar.steps.each do |step|
                if school_calendar_event_batch.start_date.between?(step.start_at, step.end_at) &&
                   school_calendar_event_batch.end_date.between?(step.start_at, step.end_at)

                  notify(
                    school_calendar_event_batch,
                    "A criação do evento #{school_calendar_event_batch.description} não foi efetuada para a escola\
                    #{unity_name} pois a mesma já possui um evento na data #{school_calendar_event_batch.start_date.strftime('%d/%m/%Y')}.",
                    user_id
                  )
                else
                  notify(
                    school_calendar_event_batch,
                    "A criação do evento #{school_calendar_event_batch.description} não foi efetuada para a escola\
                    #{unity_name} pois a data #{school_calendar_event_batch.start_date.strftime('%d/%m/%Y')} não está dentro do período letivo.",
                    user_id
                  )
                end
              end
              next
            end
          end

          raise EventsNotCreatedError unless created

          school_calendar_event_batch.update(batch_status: BatchStatus::COMPLETED)
          notify(
            school_calendar_event_batch,
            "A criação do evento em lote #{school_calendar_event_batch.description} foi finalizada.",
            user_id
          )
        rescue StandardError => error
          school_calendar_event_batch.mark_with_error!(error.message)
        end
      end
    end

    def school_calendars_days(school_calendar_event_batch, action_name)
      school_calendars = school_calendars(school_calendar_event_batch)
      events = school_calendar_event_batch.school_calendar_events
      start_date = school_calendar_event_batch.start_date
      end_date = school_calendar_event_batch.end_date

      SchoolCalendarEventDays.update_school_days(
        school_calendars,
        events,
        action_name,
        start_date,
        end_date
      )
    end

    def school_calendars(school_calendar_event_batch)
      SchoolCalendar.by_year(school_calendar_event_batch.year)
    end
  end
end
