module SchoolCalendarEventBatchManager
  class Base
    include Sidekiq::Worker

    sidekiq_options unique: :until_and_while_executing,
     unique_args: ->(args) { args }, queue: :low, on_conflict: { client: :log, server: :reject }

    protected

    def notify(source, message, user_id)
      SystemNotificationCreator.create!(
        source: source,
        title: I18n.t('navigation.school_calendar_event_batches'),
        description: message,
        users: [User.find(user_id)]
      )
    end
  end
end
