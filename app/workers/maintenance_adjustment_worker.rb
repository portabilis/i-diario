class MaintenanceAdjustmentWorker
  include Sidekiq::Worker

  def perform(entity_id, unities, user_id, maintenance_adjustment_id)
    Entity.find(entity_id).using_connection do
      maintenance_adjustment = MaintenanceAdjustment.find(maintenance_adjustment_id)

      begin
        maintenance_adjustment.mark_as_in_progress!

        if maintenance_adjustment.absence_adjustments?
          AbsenceAdjustmentsService.adjust(unities, maintenance_adjustment.year)
        end

        maintenance_adjustment.mark_as_completed!

        notify_on_message(maintenance_adjustment, user_id, success: true)
      rescue StandardError => error
        Honeybadger.notify(error)

        maintenance_adjustment.mark_as_error!(error.message)
        notify_on_message(maintenance_adjustment, user_id, success: false, error_message: error.message)
      end
    end
  end

  private

  def notify_on_message(maintenance_adjustment, user_id, success:, error_message: nil)
    scope = success ? 'maintenance_adjustment_worker.success' : 'maintenance_adjustment_worker.error'

    SystemNotificationCreator.create!(
      source: maintenance_adjustment,
      title: I18n.t("#{scope}.title"),
      description: I18n.t("#{scope}.description", error_message: error_message),
      users: [User.find(user_id)]
    )
  end
end
