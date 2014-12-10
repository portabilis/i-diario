class RolePermission < ActiveRecord::Base
  audited associated_with: :role, only: [:feature, :permission]

  has_enumeration_for :feature, with: Features
  has_enumeration_for :permission, with: Permissions

  belongs_to :role
end
