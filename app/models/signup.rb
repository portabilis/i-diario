class Signup
  include ActiveModel::Model

  attr_accessor :first_name, :last_name, :document, :student_code, :email, :password,
    :password_confirmation, :students_attributes, :without_student, :parent_role,
    :employee_role, :student_role

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :document, presence: true, if: :parent_role?
  validates :email, presence: true, if: :employee_role?
  validates :email, email: true, allow_blank: true
  validates :password, presence: true
  validates :password, confirmation: true, length: { minimum: 8 }, allow_blank: true
  validates :password_confirmation, presence: true
  validates :student_code, presence: true, if: :require_student_code?

  validates_format_of :document, with: /\d{3}.\d{3}.\d{3}-\d{2}/, message: :incorrect_format, unless: -> { document.blank? }

  validate :presence_of_default_roles
  validate :presence_of_role
  validate :uniqueness_of_document
  validate :uniqueness_of_email
  validate :presence_of_email_or_document
  validate :valid_cpf, unless: -> { document.blank? }

  def employee_role?
    employee_role == '1'
  end

  def parent_role?
    parent_role == '1'
  end

  def student_role?
    student_role == "1"
  end

  def without_student?
    without_student == '1'
  end

  def students
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
        first_name: first_name,
        last_name: last_name,
        email: email,
        cpf: document,
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
          role: parents_default_role
        )
      end

      if employee_role?
        user_role = UserRole.new(
          role: employees_default_role,
          user: user
        )

        user_role.save(validate: false)
      end

      if student_role?
        user.user_roles << UserRole.new(
          role: students_default_role
        )
      end

      user
    end
  end

  private

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

  def valid_cpf
    unless CPF.valid?(document)
      errors.add(:document, :invalid)
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

  def presence_of_role
    unless parent_role? || student_role? || employee_role?
      errors.add(:parent_role, :must_choose_one_role)
    end
  end

  def presence_of_default_roles
    if parents_default_role.blank?
      errors.add(:parent_role, :default_role_not_found, role: "pais")
    elsif employees_default_role.blank?
      errors.add(:employee_role, :default_role_not_found, role: "servidores")
    elsif students_default_role.blank?
      errors.add(:student_role, :default_role_not_found, role: "alunos")
    end
  end

  def presence_of_email_or_document
    return if errors[:email].any? || errors[:document].any?

    if email.blank? && document.blank?
      errors.add(:base, :must_inform_email_or_document)
    end
  end

  def parents_default_role
    @parents_default_role ||= general_configuration.try(:parents_default_role)
  end

  def employees_default_role
    @employees_default_role ||= general_configuration.try(:employees_default_role)
  end

  def students_default_role
    @students_defaulr_role ||= general_configuration.try(:students_default_role)
  end

  def general_configuration
    @general_configuration ||= GeneralConfiguration.first
  end
end
