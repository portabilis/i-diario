class Signup
  include ActiveModel::Model

  attr_accessor :document, :student_code, :celphone, :email, :password,
    :password_confirmation, :students_attributes, :without_student, :parent_role,
    :employee_role, :student_role

  validates :email, :password, :password_confirmation, presence: true
  validates :document, presence: true, if: :parent_role?
  validates :student_code, presence: true, if: :require_student_code?
  validates :celphone, format: { with: /\A\([0-9]{2}\)\ [0-9]{8,9}\z/i }, allow_blank: true
  validates :password, confirmation: true, length: { minimum: 8 }, allow_blank: true
  validates :email, email: true, allow_blank: true
  validate :uniqueness_of_document
  validate :uniqueness_of_email

  def without_student?
    without_student == "1"
  end

  def parent_role?
    parent_role == "1"
  end

  def student_role?
    student_role == "1"
  end

  def employee_role?
    employee_role == "1"
  end

  def students
    return []
    students = []

    (students_attributes || []).each do |_, attribute|
      next if %w(false f 0).include?( attribute["selected"] )

      if student = Student.find_by(api_code: attribute["api_code"])
        students << student
      else
        students << Student.create!(
          name: attribute["name"],
          api_code: attribute["api_code"],
          api: true
        )
      end
    end

    students
  end

  def save
    return false unless valid?

    ActiveRecord::Base.transaction do
      user = User.create!(
        email: email,
        cpf: document,
        phone: celphone,
        password: password,
        password_confirmation: password_confirmation,
        status: status,
        kind: kind
      )

      if parent_role?
        students.each do |student|
          user.students << student
        end

        user.user_roles << UserRole.new(
          role: general_configuration.try(:parents_default_role)
        )
      end

      if employee_role?
        user.user_roles << UserRole.new(
          role: general_configuration.try(:employees_default_role)
        )
      end

      if student_role?
        user.user_roles << UserRole.new(
          role: general_configuration.try(:students_default_role)
        )
      end

      user
    end
  end

  protected

  def require_student_code?
    parent_role? && !without_student?
  end

  def status
    if parent_role? && !student_role? && !employee_role?
      UserStatus::ACTIVED
    else
      UserStatus::PENDING
    end
  end

  def kind
    if parent_role?
      RoleKind::PARENT
    elsif student_role?
      RoleKind::STUDENT
    else
      RoleKind::EMPLOYEE
    end
  end

  def uniqueness_of_document
    return if document.blank?

    if User.exists?(cpf: document)
      errors.add(:document, :taken)
    end
  end

  def uniqueness_of_email
    return if email.blank?

    if User.exists?(email: email)
      errors.add(:email, :taken)
    end
  end

  def general_configuration
    @general_configuration ||= GeneralConfiguration.first
  end
end
