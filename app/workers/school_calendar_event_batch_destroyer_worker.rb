class SchoolCalendarEventBatchDestroyerWorker
  class EventsNotDestroyedError < StandardError; end

  include Sidekiq::Worker

  sidekiq_options unique: :until_and_while_executing, queue: :low

  def perform(entity_id, school_calendar_event_batch_id)
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
          rescue ActiveRecord::RecordNotDestroyed => error
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
