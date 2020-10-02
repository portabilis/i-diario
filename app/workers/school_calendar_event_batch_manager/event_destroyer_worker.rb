module SchoolCalendarEventBatchManager
  class EventDestroyerWorker < Base
    class EventsNotDestroyedError < StandardError; end

    EVENT_NOT_DESTROYED = 'Não foi possível excluir o evento'.freeze

    def perform(entity_id, school_calendar_event_batch_id, user_id)
      Entity.find(entity_id).using_connection do
        begin
          school_calendar_event_batch = SchoolCalendarEventBatch.find(school_calendar_event_batch_id)
          events = SchoolCalendarEvent.where(batch_id: school_calendar_event_batch.id)

          return if events.blank? && school_calendar_event_batch.destroy!

          destroyed = false

          events.each do |event|
            begin
              event.destroy!

              destroyed = true
            rescue ActiveRecord::RecordNotDestroyed
              unity_name = Unity.find_by(id: school_calendar.unity_id)&.name
              notify(
                school_calendar_event_batch,
                "#{EVENT_NOT_DESTROYED}: #{school_calendar_event_batch.description} em #{unity_name}",
                user_id
              )

              next
            end
          end

          raise EventsNotDestroyedError unless destroyed

          school_calendar_event_batch.destroy!
        rescue StandardError => error
          school_calendar_event_batch.mark_with_error!(error.message)
        end
      end
    end
  end
end
