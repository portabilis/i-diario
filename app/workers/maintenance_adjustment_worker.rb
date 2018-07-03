class MaintenanceAdjustmentWorker
  include Sidekiq::Worker

  def perform(entity_id, unities, user_id, maintenance_adjustment_id)
    entity = Entity.find(entity_id)

    entity.using_connection do
      maintenance_adjustment = MaintenanceAdjustment.find(maintenance_adjustment_id)

      begin
        maintenance_adjustment.update_attribute(:status, MaintenanceAdjustmentStatus::IN_PROGRESS)

        case maintenance_adjustment.kind
          when MaintenanceAdjustmentKinds::ABSENCE_ADJUSTMENTS then AbsenceAdjustmentsService.adjust(unities, maintenance_adjustment.year)
        end

        maintenance_adjustment.update_attributes(
          status: MaintenanceAdjustmentStatus::COMPLETED,
          error_message: ''
        )

        notify_on_message(maintenance_adjustment, user_id)
      rescue Exception => e
        Honeybadger.notify(e)

        maintenance_adjustment.update_attributes(
          status: MaintenanceAdjustmentStatus::ERROR,
          error_message: e.message
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
