class SchoolCalendarSynchronizerWorker
  include Sidekiq::Worker

  def perform(entity_id, school_calendar, user_id)
    entity = Entity.find(entity_id)

    entity.using_connection do
      worker = WorkerState.find_by!(job_id: self.jid)
      unity = Unity.find(school_calendar['unity_id']).name

      begin
        SchoolCalendarSynchronizerService.synchronize(school_calendar)

        worker.mark_as_completed!

        notify_on_message(user_id, I18n.t('school_calendar_synchronizer_worker.success', unity: unity))
      rescue Exception => e
        Honeybadger.notify(e)

        worker.mark_with_error!(e.message)

        notify_on_message(user_id, I18n.t('school_calendar_synchronizer_worker.error', unity: unity))
      end
    end
  end

  private

  def notify_on_message(user_id, message)
    SystemNotificationCreator.create!(
      generic: true,
      title: I18n.t('school_calendar_synchronizer_worker.title'),
      description: message,
      users: [User.find(user_id)]
    )
  end
end
