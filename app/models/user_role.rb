class UserRole < ActiveRecord::Base
  acts_as_copy_target
  audited associated_with: :user, only: [:role_id, :unity_id]

  belongs_to :user
  belongs_to :role
  belongs_to :unity

  validates :user, :role, presence: true
  validates :unity, presence: true, if: :require_unity?

  delegate :name, :access_level_humanize, :administrator?, :teacher?, :employee?, :parent?, :student?, to: :role, prefix: true, allow_nil: true
  delegate :name, to: :unity, prefix: true, allow_nil: true

  def to_s
    if require_unity?
      "#{role_name} (Nível: #{role_access_level_humanize}) - #{unity_name}"
    else
      "#{role_name} (Nível: #{role_access_level_humanize})"
    end
  end

  private

  def require_unity?
    role_teacher? || role_employee?
  end
end
