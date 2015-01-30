class UserRole < ActiveRecord::Base
  belongs_to :user
  belongs_to :role
  belongs_to :unity

  validates :user, :role, presence: true
  validates :unity, presence: true, if: :role_employee?

  delegate :name, :kind_humanize, :employee?, to: :role, prefix: true, allow_nil: true
  delegate :name, to: :unity, prefix: true, allow_nil: true

  def to_s
    if role_employee?
      "#{role_name} - #{unity_name}"
    else
      role_kind_humanize
    end
  end
end
