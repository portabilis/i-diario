module SchoolCalendarEventBatchManager
  class EventCreatorWorker < Base
    class EventsNotCreatedError < StandardError; end

    def perform(entity_id, school_calendar_event_batch_id, user_id)
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
                event.legend = school_calendar_event_batch.legend
                event.show_in_frequency_record = school_calendar_event_batch.show_in_frequency_record
                event.save! if event.changed?

                created = true
              end
            rescue ActiveRecord::RecordInvalid
              unity_name = Unity.find_by(id: school_calendar.unity_id)&.name
              notify(
                school_calendar_event_batch,
                "A criação do evento #{school_calendar_event_batch.description} não foi efetuada para a escola\
                #{unity_name} pois a mesma já possui um evento na data #{school_calendar_event_batch.start_date}.",
                user_id
              )

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
  end
end
