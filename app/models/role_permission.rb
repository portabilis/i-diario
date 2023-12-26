class RolePermission < ApplicationRecord
  acts_as_copy_target
  audited associated_with: :role, only: [:feature, :permission]

  has_enumeration_for :feature, with: Features
  has_enumeration_for :permission, with: Permissions

  belongs_to :role, touch: true

  def self.can_show?(feature)
    where(arel_table[:feature].eq(feature)).
      where(arel_table[:permission].in([Permissions::CHANGE, Permissions::READ])).exists?
  end

  def self.can_change?(feature)
    where(arel_table[:feature].eq(feature)).
      where(arel_table[:permission].eq(Permissions::CHANGE)).exists?
  end

  def access_level_has_feature?(access_level)
    return unless feature
    FeaturesAccessLevels.send(access_level+'_features').include? feature.to_sym
  end
end
