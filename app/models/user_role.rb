class UserRole < ActiveRecord::Base
  audited associated_with: :user, only: [:role_id, :unity_id]

  belongs_to :user
  belongs_to :role
  belongs_to :unity

  validates :user, :role, presence: true
  validates :unity, presence: true, if: :role_teacher?

  delegate :name, :access_level_humanize, :teacher?, to: :role, prefix: true, allow_nil: true
  delegate :name, to: :unity, prefix: true, allow_nil: true

  def to_s
    if role_teacher?
      "#{role_name} - #{unity_name}"
    else
      role_access_level_humanize
    end
  end
end
