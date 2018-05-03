class SchoolCalendarSetterByStepWorker
  include Sidekiq::Worker

  def perform(entity_id, school_calendars, user_id)
    entity = Entity.find(entity_id)

    entity.using_connection do
      worker = WorkerState.find_by!(job_id: self.jid)

      begin
        SchoolCalendarClassroomStepSetter.set_school_calendar_classroom_step(school_calendars)

        worker.mark_as_completed!

        notify_on_message(user_id)
      rescue Exception => e
        Honeybadger.notify(e)

        worker.mark_with_error!(e.message)
      end
    end
  end

  private

  def notify_on_message(user_id)
    SystemNotificationCreator.create!(
      generic: true,
      title: I18n.t('school_calendar_setter_by_step_worker.title'),
      description: I18n.t('school_calendar_setter_by_step_worker.description'),
      users: [User.find(user_id)]
    )
  end
end
