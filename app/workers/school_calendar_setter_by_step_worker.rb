class SchoolCalendarSetterByStepWorker
  include Sidekiq::Worker

  def perform(entity_id, school_calendars, user_id)
    entity = Entity.find(entity_id)

    entity.using_connection do
      worker = WorkerState.where(kind: 'SchoolCalendarSetterByStepWorker').first

      begin
        SchoolCalendarClassroomStepSetter.set_school_calendar_classroom_step(school_calendars)

        worker.mark_as_completed!

        notify_on_message(user_id)
      rescue Exception => e
        worker.mark_with_error!(e.message)
      end
    end
  end

  private

  def notify_on_message(user_id)
    SystemNotificationCreator.create!(
      generic: true,
      title: 'Ajustes realizados com sucesso',
      description: 'Os ajustes referente as etapas de turmas dos calendários letivos sincronizados foram realizados com sucesso.',
      users: [User.find(user_id)]
    )
  end
end
