class CurrentRoleForm
  include ActiveModel::Model

  attr_accessor :current_user_id,
                :current_user_role_id,
                :teacher_id,
                :current_unity_id,
                :current_classroom_id,
                :current_discipline_id,
                :id,
                :current_unity_id,
                :assumed_teacher_id

  validates :current_user_role_id, presence: true
  validates :current_classroom_id, :current_discipline_id,  presence: true, if: :require_allocation?
  validates :current_unity_id,  presence: true, if: :require_unity?

  def initialize(attributes = {})
    @params = attributes

    super
  end

  def save
    return false unless valid?
    @params[:current_classroom_id] = @params[:current_discipline_id] = nil unless require_allocation?
    @params[:current_unity_id] = nil unless require_unity?
    current_user.update_attributes(@params)
    current_user.save!
  end

  private

  def current_user
    @current_user ||= User.find_by_id(id)
  end

  def user_role
    @user_role ||= UserRole.find_by_id(current_user_role_id)
  end

  def access_level
    @access_level ||= user_role.try(:role).try(:access_level)
  end

  def user_teacher
    @user_teacher ||= Teacher.find_by_id(assumed_teacher_id)
  end

  def require_allocation?
    access_level == AccessLevel::TEACHER || user_teacher
  end

  def require_unity?
    access_level == AccessLevel::ADMINISTRATOR
  end

  def is_admin?
    access_level == AccessLevel::ADMINISTRATOR
  end

end
