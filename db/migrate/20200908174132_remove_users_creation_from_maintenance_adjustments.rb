class RemoveUsersCreationFromMaintenanceAdjustments < ActiveRecord::Migration
  def change
    MaintenanceAdjustment.where(kind: 'creating_users_for_students').each(&:destroy)
  end
end
