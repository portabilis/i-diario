class MaintenanceAdjustmentWorker
  include Sidekiq::Worker

  def perform(entity_id, unities, user_id, maintenance_adjustment_id)
    Entity.find(entity_id).using_connection do
      maintenance_adjustment = MaintenanceAdjustment.find(maintenance_adjustment_id)

      begin
        maintenance_adjustment.update(status: MaintenanceAdjustmentStatus::IN_PROGRESS)

        if maintenance_adjustment.absence_adjustments?
          AbsenceAdjustmentsService.adjust(unities, maintenance_adjustment.year)
        end

        maintenance_adjustment.update(
          status: MaintenanceAdjustmentStatus::COMPLETED,
          error_message: ''
        )

        notify_on_message(maintenance_adjustment, user_id)
      rescue StandardError => error
        Honeybadger.notify(error)

        maintenance_adjustment.update(
          status: MaintenanceAdjustmentStatus::ERROR,
          error_message: error.message
        )
      end
    end
  end

  private

  def notify_on_message(maintenance_adjustment, user_id)
    SystemNotificationCreator.create!(
      source: maintenance_adjustment,
      title: I18n.t('maintenance_adjustment_worker.title'),
      description: I18n.t('maintenance_adjustment_worker.description'),
      users: [User.find(user_id)]
    )
  end
end
