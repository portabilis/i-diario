class CurrentRoleForm
  include ActiveModel::Model

  attr_accessor :current_user_id,
                :current_user_role_id,
                :teacher_id,
                :current_classroom_id,
                :current_discipline_id,
                :id,
                :current_unity_id,
                :assumed_teacher_id,
                :current_school_year

  validates :current_user_role_id, presence: true
  validates :current_school_year, presence: true, if: :require_year?, unless: :unity_is_cost_center?
  validates :current_classroom_id, presence: true, if: :is_teacher?
  validates :current_discipline_id, :assumed_teacher_id, presence: true, if: :require_allocation?
  validates :current_unity_id, presence: true, if: :require_unity?
  validate :classroom_belongs_to_teacher?, if: :require_allocation?
  validate :discipline_belongs_to_teacher?, if: :require_allocation?

  def initialize(attributes = {})
    @params = attributes

    super
  end

  def save
    return false unless valid?
    @params[:assumed_teacher_id] =
      @params[:current_classroom_id] = @params[:current_discipline_id] = nil unless require_allocation?

    @params[:current_unity_id] = nil unless require_unity?

    current_user.update_attributes(@params)
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

  def classroom
    @classroom ||= Classroom.find_by_id(current_classroom_id)
  end

  def require_allocation?
    access_level == AccessLevel::TEACHER || classroom
  end

  def is_admin?
    access_level == AccessLevel::ADMINISTRATOR
  end

  def is_employee?
    access_level == AccessLevel::EMPLOYEE
  end

  def is_teacher?
    access_level == AccessLevel::TEACHER
  end

  def require_year?
    is_admin? || is_employee? || is_teacher?
  end

  def require_unity?
    is_admin? || is_employee? || is_teacher?
  end

  def unity_is_cost_center?
    return false if @params[:current_unity_id].blank?
    Unity.find(@params[:current_unity_id]).unit_type == 'cost_center'
  end

  def classroom_belongs_to_teacher?
    return if teacher_relation_fetcher.exists_classroom_in_relation?

    errors.add(:current_classroom_id, :not_belongs_to_teacher)
  end

  def discipline_belongs_to_teacher?
    return if teacher_relation_fetcher.exists_discipline_in_relation?

    errors.add(:current_discipline_id, :not_belongs_to_teacher)
  end

  def teacher_relation_fetcher
    params = { teacher_id: assumed_teacher_id }
    params[:discipline_id] = current_discipline_id
    params[:classroom] = current_classroom_id

    TeacherRelationFetcher.new(params)
  end
end
