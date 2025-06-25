class UserPermission < ApplicationRecord
  acts_as_copy_target
  audited associated_with: :user, only: %i[feature permission]

  has_enumeration_for :feature, with: Features
  has_enumeration_for :permission, with: Permissions

  belongs_to :user, touch: true

  def self.can_show?(feature)
    has_permission_for_feature?(feature, [Permissions::CHANGE, Permissions::READ])
  end

  def self.can_change?(feature)
    has_permission_for_feature?(feature, Permissions::CHANGE)
  end

  def access_level_has_feature?(access_level)
    return unless feature

    FeaturesAccessLevels.send(access_level + '_features').include? feature.to_sym
  end

  def self.has_permission_for_feature?(feature, permissions)
    by_feature(feature).by_permissions(permissions).exists?
  end

  def self.by_feature(feature)
    where(arel_table[:feature].eq(feature))
  end

  def self.by_permissions(permissions)
    permissions_filter = Array(permissions)
    where(arel_table[:permission].in(permissions_filter))
  end

  private_class_method :has_permission_for_feature?, :by_feature, :by_permissions
end
