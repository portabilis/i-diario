class SetPermissionToCreateEventBatchesToAdmins < ActiveRecord::Migration
  def change
    Role.where(access_level: AccessLevel::ADMINISTRATOR).each do |role|
      role.permissions.create!(feature: 'school_calendar_event_batches', permission: Permissions::CHANGE)
    end
  end
end
