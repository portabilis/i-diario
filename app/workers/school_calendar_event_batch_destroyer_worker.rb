class SchoolCalendarEventBatchDestroyerWorker
  class EventsNotDestroyedError < StandardError; end

  include Sidekiq::Worker

  sidekiq_options unique: :until_and_while_executing, queue: :low

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
            notify("#{EVENT_NOT_DESTROYED}: #{school_calendar_event_batch.description} em #{unity_name}", user_id)

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

  private

  def notify(message, user_id)
    notification = SystemNotification.create!(
      generic: true,
      source_type: 'SchoolCalendarEventBatch',
      title: I18n.t('navigation.school_calendar_event_batches'),
      description: message
    )

    notification.targets.create!(user: User.find(user_id))
  end
end
