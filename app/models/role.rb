class Role < ActiveRecord::Base
  audited
  has_associated_audits

  include Audit

  belongs_to :author, class_name: "User"

  has_many :permissions, class_name: "RolePermission", dependent: :destroy

  has_many :student_default_roles, class_name: 'GeneralConfiguration', foreign_key: 'students_default_role_id'
  has_many :employees_default_roles, class_name: 'GeneralConfiguration', foreign_key: 'employees_default_role_id'
  has_many :parents_default_roles, class_name: 'GeneralConfiguration', foreign_key: 'parents_default_role_id'

  accepts_nested_attributes_for :permissions

  validates :author, :name, presence: true
  validates :name, uniqueness: { case_sensitive: false }, allow_blank: true

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
    name
  end
end
