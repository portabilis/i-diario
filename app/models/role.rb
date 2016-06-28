class Role < ActiveRecord::Base
  audited
  has_associated_audits

  include Audit

  has_enumeration_for :kind, with: RoleKind, create_helpers: true
  has_enumeration_for :access_level, with: AccessLevel, create_helpers: true

  belongs_to :author, class_name: "User"

  has_many :permissions, class_name: "RolePermission", dependent: :destroy
  has_many :user_roles, dependent: :restrict_with_error
  has_many :student_default_roles, class_name: 'GeneralConfiguration', foreign_key: 'students_default_role_id'
  has_many :employees_default_roles, class_name: 'GeneralConfiguration', foreign_key: 'employees_default_role_id'
  has_many :parents_default_roles, class_name: 'GeneralConfiguration', foreign_key: 'parents_default_role_id'

  accepts_nested_attributes_for :permissions
  accepts_nested_attributes_for :user_roles, reject_if: :all_blank, allow_destroy: true

  validates :author, :name, :kind, presence: true
  validates :name, uniqueness: { case_sensitive: false }, allow_blank: true
  validate :uniqueness_of_user_unity

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
    "#{name} - Tipo: #{kind_humanize}"
  end

  protected

  def uniqueness_of_user_unity
    return unless user_roles

    user_unity = []

    user_roles.reject(&:marked_for_destruction?).each do |user_role|
      if user_unity.include?([user_role.user_id, user_role.unity_id])
        errors.add(:user_roles, :invalid)
        user_role.errors.add(:user_id, :taken)
      else
        user_unity.push([user_role.user_id, user_role.unity_id])
      end
    end
  end
end
