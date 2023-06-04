class SetPermissionToCreateEventBatchesToAdmins < ActiveRecord::Migration[4.2]
  def change
    Role.where(access_level: AccessLevel::ADMINISTRATOR).each do |role|
      role_permission = role.permissions.build(feature: 'school_calendar_event_batches', permission: Permissions::CHANGE)
      role_permission.save_without_auditing
    end
  end
end
