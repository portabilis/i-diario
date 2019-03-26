class Role < ActiveRecord::Base
  audited
  has_associated_audits
  acts_as_copy_target

  include Audit

  has_enumeration_for :access_level, with: AccessLevel, create_helpers: true

  belongs_to :author, class_name: "User"

  has_many :permissions, class_name: "RolePermission", dependent: :destroy
  has_many :user_roles, dependent: :restrict_with_error
  has_many :student_default_roles, class_name: 'GeneralConfiguration', foreign_key: 'students_default_role_id'
  has_many :employees_default_roles, class_name: 'GeneralConfiguration', foreign_key: 'employees_default_role_id'
  has_many :parents_default_roles, class_name: 'GeneralConfiguration', foreign_key: 'parents_default_role_id'

  accepts_nested_attributes_for :permissions
  accepts_nested_attributes_for :user_roles, reject_if: :all_blank, allow_destroy: true

  before_validation :remove_not_unique_user_unity

  validates :author, :name, :access_level, presence: true
  validates :name, uniqueness: { case_sensitive: false }, allow_blank: true

  validate :permissions_must_match_access_level

  scope :ordered, -> { order(arel_table[:name].asc) }

  def build_permissions!
    Features.list.each do |feature|
      unless permissions.where(feature: feature).exists?
        permissions.new(
          feature: feature,
          permission: Permissions::DENIED
        )
      end
    end
  end

  def can_show?(feature)
    permissions.can_show?(feature)
  end

  def can_change?(feature)
    permissions.can_change?(feature)
  end

  def to_s
    "#{name} - Nível: #{access_level_humanize}"
  end

  protected

  def permissions_must_match_access_level
    return unless access_level
    permissions.each do |permission|
      next if permission.permission == Permissions::DENIED
      unless permission.access_level_has_feature?(access_level)
        errors.add(:permissions, I18n.t('roles.errors.permission_must_match_access_level', feature: permission.feature_humanize, access_level: access_level_humanize))
      end
    end
  end

  def remove_not_unique_user_unity
    return unless user_roles

    user_unity = []

    user_roles.each do |user_role|
      next if user_role.marked_for_destruction?

      if user_unity.include?([user_role.user_id, user_role.unity_id])
        user_role.mark_for_destruction
      else
        user_unity.push([user_role.user_id, user_role.unity_id])
      end
    end
  end
end
