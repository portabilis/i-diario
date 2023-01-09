class UserRole < ApplicationRecord
  include Searchable

  acts_as_copy_target
  audited associated_with: :user, only: [:role_id, :unity_id]

  belongs_to :user
  belongs_to :role
  belongs_to :unity

  validates :user, :role, presence: true
  validates :unity, presence: true, if: :require_unity?

  delegate :access_level, :name, :access_level_humanize, :administrator?, :teacher?, :employee?, to: :role,
                                                                                                 prefix: true,
                                                                                                 allow_nil: true

  delegate :name, to: :unity, prefix: true, allow_nil: true

  after_save :update_current_user_role_id, on: :update
  after_create :set_current_user_role_id

  before_destroy :set_current_user_role_id_nil

  scope :user_name, lambda { |user_name|
    joins(:user)
    .where("users.fullname ILIKE ?", "%#{I18n.transliterate(user_name.squish)}%")
    .order('users.fullname')
  }
  scope :unity_name, ->(unity_name) { joins(:unity).merge(Unity.search_name(unity_name)) }

  def to_s
    if require_unity?
      "#{role_name} (Nível: #{role_access_level_humanize}) - #{unity_name}"
    else
      "#{role_name} (Nível: #{role_access_level_humanize})"
    end
  end

  def name
    to_s
  end

  def can_change_school_year?
    return false unless role

    role.can_change?('change_school_year')
  end
  alias can_change_school_year can_change_school_year?

  private

  def require_unity?
    role_teacher? || role_employee?
  end

  def update_current_user_role_id
    return if unity_id == unity_id_was
    return if user.current_user_role_id != id

    user.set_current_user_role!
  end

  def set_current_user_role_id_nil
    return if user.current_user_role_id != id

    user.clear_allocation
  end

  def set_current_user_role_id
    user.set_current_user_role! if user.current_user_role_id.blank?
  end
end
