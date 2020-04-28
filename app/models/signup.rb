class Signup
  include ActiveModel::Model

  attr_accessor :first_name, :last_name, :document, :email, :password,
    :password_confirmation, :employee_role

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true, if: :employee_role?
  validates :email, email: true, allow_blank: true
  validates :password, presence: true
  validates :password, confirmation: true, length: { minimum: 8 }, allow_blank: true
  validates :password_confirmation, presence: true

  validates_format_of :document, with: /\d{3}.\d{3}.\d{3}-\d{2}/, message: :incorrect_format, unless: -> { document.blank? }

  validate :presence_of_default_roles
  validate :presence_of_role
  validate :uniqueness_of_document
  validate :uniqueness_of_email
  validate :presence_of_email_or_document
  validate :valid_cpf, unless: -> { document.blank? }

  validates_format_of :document, with: /\d{3}.\d{3}.\d{3}-\d{2}/, message: :incorrect_format, unless: -> { document.blank? }

  def employee_role?
    employee_role == '1'
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

      if employee_role?
        user_role = UserRole.new(
          role: employees_default_role,
          user: user
        )

        user_role.save(validate: false)
      end

      user
    end
  end

  private

  def status
    UserStatus::PENDING
  end

  def kind
    RoleKind::EMPLOYEE
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

    errors.add(:email, :taken) if User.where('LOWER(email) = LOWER(?)', email).exists?
  end

  def presence_of_role
    unless employee_role?
      errors.add(:employee_role, :must_choose_one_role)
    end
  end

  def presence_of_default_roles
    if employees_default_role.blank?
      errors.add(:employee_role, :default_role_not_found, role: "servidores")
    end
  end

  def presence_of_email_or_document
    return if errors[:email].any? || errors[:document].any?

    if email.blank? && document.blank?
      errors.add(:base, :must_inform_email_or_document)
    end
  end

  def employees_default_role
    @employees_default_role ||= general_configuration.try(:employees_default_role)
  end

  def general_configuration
    @general_configuration ||= GeneralConfiguration.first
  end
end
