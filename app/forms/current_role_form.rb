class CurrentRoleForm
  include ActiveModel::Model

  attr_accessor :current_user, :current_user_role, :current_user_role_id, :current_classroom, :current_teacher,
                :current_classroom_id, :current_discipline_id, :current_unity, :current_unity_id,
                :current_teacher_id, :current_school_year, :current_knowledge_area_id,
                :current_knowledge_area

  validates :current_user, presence: true

  with_options if: :current_user do
    validates :current_user_role,   presence: true
    validates :current_classroom,   presence: true, if: :teacher?
    validates :current_unity,       presence: true, if: :require_unity?
    validates :current_school_year, presence: true, if: :require_year?

    with_options if: :require_allocation? do
      validates :current_teacher, presence: true
      validates :current_discipline_id, presence: true
      validates :current_knowledge_area_id, presence: true
      validate :classroom_belongs_to_teacher?
      validate :discipline_belongs_to_teacher?, if: :current_discipline_id
      validate :knowledge_area_belongs_to_teacher?, if: :current_knowledge_area_id
    end
  end

  def initialize(attributes = {})
    @params = attributes

    super

    set_defaults
  end

  def save
    return false unless valid?

    current_user.update(user_attributes)
  end

  private

  def user_attributes
    attributes = @params.slice(
      :current_discipline_id,
      :current_school_year,
      :current_knowledge_area_id
    )
    attributes.merge!(
      current_unity_id: current_unity&.id,
      current_classroom_id: current_classroom&.id,
      current_user_role_id: current_user_role&.id,
      assumed_teacher_id: current_teacher&.id
    )

    unless require_allocation?
      attributes[:assumed_teacher_id] = nil
      attributes[:current_classroom_id] = nil
      attributes[:current_discipline_id] = nil
      attributes[:current_knowledge_area_id] = nil
    end

    attributes[:current_unity_id] = nil unless require_unity?
    attributes
  end

  def require_allocation?
    return false if changed_to_parent_or_student?

    teacher? || current_classroom
  end

  def teacher?
    return false if changed_to_parent_or_student?

    current_user&.teacher?
  end

  def require_year?
    !unity_is_cost_center? && !changed_to_parent_or_student? && is_admin_or_employee_or_teacher?
  end

  def require_unity?
    !changed_to_parent_or_student? && is_admin_or_employee_or_teacher?
  end

  def is_admin_or_employee_or_teacher?
    current_user_role&.role&.access_level&.in?([
      AccessLevel::ADMINISTRATOR,
      AccessLevel::EMPLOYEE,
      AccessLevel::TEACHER
    ])
  end

  def unity_is_cost_center?
    current_unity&.unit_type == 'cost_center'
  end

  def classroom_belongs_to_teacher?
    return if teacher_relation_fetcher.exists_classroom_in_relation?

    errors.add(:current_classroom_id, :not_belongs_to_teacher)
  end

  def discipline_belongs_to_teacher?
    return if teacher_relation_fetcher.exists_discipline_in_relation?

    errors.add(:current_discipline_id, :not_belongs_to_teacher)
  end

  def knowledge_area_belongs_to_teacher?
    return if teacher_relation_fetcher.exists_knowledge_area_in_relation?

    errors.add(:current_knowledge_area_id, :not_belongs_to_teacher)
  end

  def teacher_relation_fetcher
    params = {
      teacher_id: current_teacher&.id,
      discipline_id: current_discipline_id,
      classroom: current_classroom&.id,
      knowledge_areas: [current_knowledge_area_id]
    }

    TeacherRelationFetcher.new(params)
  end

  def changed_to_parent_or_student?
    return @changed_to_parent_or_student unless @changed_to_parent_or_student.nil?

    @changed_to_parent_or_student = begin
      return false if current_user_role.nil?

      current_user_role.role.access_level.in? [AccessLevel::PARENT, AccessLevel::STUDENT]
    end
  end

  def set_defaults
    self.current_user      ||= current_user
    self.current_user_role ||= UserRole.find(current_user_role_id)  if current_user_role_id.present?
    self.current_classroom ||= Classroom.find(current_classroom_id) if current_classroom_id.present?
    self.current_unity     ||= Unity.find(current_unity_id)         if current_unity_id.present?
    self.current_teacher   ||= Teacher.find(current_teacher_id)     if current_teacher_id.present?
    self.current_unity     ||= current_user_role.unity              if current_user_role
    self.current_knowledge_area ||= KnowledgeArea.find(current_knowledge_area_id) if current_knowledge_area_id.present?

    set_default_user_role
  end

  def set_default_user_role
    return unless current_user
    return if current_user_role
    return if current_user.access_levels.size > 1

    self.current_user_role = current_user.current_user_role || current_user.user_roles.first
  end
end
