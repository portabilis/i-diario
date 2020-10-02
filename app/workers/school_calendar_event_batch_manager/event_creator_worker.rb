module SchoolCalendarEventBatchManager
  class EventCreatorWorker < Base
    class EventsNotCreatedError < StandardError; end

    EVENT_NOT_CREATED = 'Não foi possível criar o evento'.freeze

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
              notify("#{EVENT_NOT_CREATED}: #{school_calendar_event_batch.description} em #{unity_name}", user_id)

              next
            end
          end

          raise EventsNotCreatedError unless created

          school_calendar_event_batch.update(batch_status: BatchStatus::COMPLETED)
        rescue StandardError => error
          school_calendar_event_batch.mark_with_error!(error.message)
        end
      end
    end
  end
end
