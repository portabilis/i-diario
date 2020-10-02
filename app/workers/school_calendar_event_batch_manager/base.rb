module SchoolCalendarEventBatchManager
  class Base
    include Sidekiq::Worker

    sidekiq_options unique: :until_and_while_executing, queue: :low

    protected

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
end
