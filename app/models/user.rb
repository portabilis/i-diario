class User < ApplicationRecord
  acts_as_copy_target

  audited allow_mass_assignment: true,
    only: [:email, :first_name, :last_name, :phone, :cpf, :login, :authorize_email_and_sms, :student_id, :status,
           :encrypted_password, :teacher_id, :assumed_teacher_id, :current_unity_id, :current_classroom_id,
           :current_discipline_id, :current_school_year, :current_user_role_id, :current_knowledge_area_id]
  has_associated_audits

  include Audit
  include Filterable
  include Searchable

  devise :database_authenticatable, :recoverable, :rememberable,
         :trackable, :validatable, :lockable

  attr_accessor :credentials, :has_to_validate_receive_news_fields

  has_enumeration_for :kind, with: RoleKind, create_helpers: true
  has_enumeration_for :status, with: UserStatus, create_helpers: true

  after_save :update_fullname_tokens
  before_save :remove_spaces_from_name
  after_validation :status_changed

  before_destroy :clear_allocation
  before_validation :verify_receive_news_fields

  belongs_to :student
  belongs_to :teacher
  belongs_to :assumed_teacher, foreign_key: :assumed_teacher_id, class_name: 'Teacher'
  belongs_to :current_discipline, foreign_key: :current_discipline_id, class_name: 'Discipline'
  belongs_to :current_knowledge_area, foreign_key: :current_knowledge_area_id, class_name: 'KnowledgeArea'
  belongs_to :current_user_role, class_name: 'UserRole'
  belongs_to :classroom, foreign_key: :current_classroom_id
  belongs_to :discipline, foreign_key: :current_discipline_id
  belongs_to :unity, foreign_key: :current_unity_id

  has_many :logins, class_name: "UserLogin", dependent: :destroy
  has_many :synchronizations, class_name: "IeducarApiSynchronization", foreign_key: :author_id,
    dependent: :restrict_with_error
  has_many :system_notification_targets, dependent: :destroy
  has_many :system_notifications, -> { includes(:source) }, through: :system_notification_targets,
    source: :system_notification
  has_many :unread_notifications, -> { where(system_notification_targets: { read: false }) },
    through: :system_notification_targets, source: :system_notification
  has_many :ieducar_api_exam_postings, class_name: "IeducarApiExamPosting", foreign_key: :author_id,
    dependent: :restrict_with_error
  has_and_belongs_to_many :students, dependent: :restrict_with_error
  has_many :user_roles, -> { includes(:role) }, dependent: :destroy
  has_many :roles, through: :user_roles

  accepts_nested_attributes_for :user_roles, reject_if: :all_blank, allow_destroy: true

  mount_uploader :profile_picture, UserProfilePictureUploader

  validates :first_name, presence: true
  validates :cpf, mask: { with: "999.999.999-99", message: :incorrect_format }, allow_blank: true,
    uniqueness: { case_sensitive: false }
  validates :phone, format: { with: /\A\([0-9]{2}\)\ [0-9]{8,9}\z/i }, allow_blank: true
  validates :email, email: true, allow_blank: true
  validates :password, length: { minimum: 8 }, allow_blank: true
  validates :login, uniqueness: true, allow_blank: true
  validates :teacher_id, uniqueness: true, allow_blank: true

  validates_associated :user_roles

  validate :valid_password
  validate :email_reserved_for_student
  validate :presence_of_email_or_cpf
  validate :validate_receive_news_fields, if: :has_to_validate_receive_news_fields?
  validate :can_not_be_a_cpf
  validate :can_not_be_an_email
  validate :validate_student_presence, if: :only_student?

  scope :ordered, -> { order(arel_table[:fullname].asc) }
  scope :email_ordered, -> { order(email: :asc) }
  scope :authorized_email_and_sms, -> { where(arel_table[:authorize_email_and_sms].eq(true)) }
  scope :with_phone, -> { where(arel_table[:phone].not_eq(nil)).where(arel_table[:phone].not_eq("")) }
  scope :admin, -> { where(arel_table[:admin].eq(true)) }
  scope :by_unity_id, lambda { |unity_id| joins(:user_roles).where(user_roles: { unity_id: unity_id }) }
  scope :by_current_unity_id, lambda { |unity_id| where(current_unity_id: unity_id) }
  scope :by_current_school_year, ->(year) { where(current_school_year: year) }

  #search scopes
  scope :by_name, lambda { |name| where("fullname ILIKE ?", "%#{I18n.transliterate(name.squish)}%") }
  scope :email, lambda { |email| where("email ILIKE unaccent(?)", "%#{email}%")}
  scope :login, lambda { |login| where("login ILIKE unaccent(?)", "%#{login}%")}
  scope :by_cpf, lambda { |cpf|
    where("REGEXP_REPLACE(cpf, '[^0-9]+', '', 'g') ILIKE REGEXP_REPLACE(?, '[^0-9|%]+', '', 'g')", "%#{cpf}%")
  }
  scope :status, lambda { |status| where status: status }

  delegate :can_change_school_year?, to: :current_user_role, allow_nil: true

  def self.current=(user)
    Thread.current[:user] = user
  end

  def self.current
    Thread.current[:user]
  end

  def self.to_csv
    attributes = [
      'Nome',
      'Sobrenome',
      'E-mail',
      'Nome de usuário',
      'Celular',
      'CPF',
      'Status',
      'Aluno vinculado',
      'Professor Vinculado',
      'Permissões',
      'Data de expiração'
    ]

    CSV.generate(headers: true) do |csv|
      csv << attributes

      users = all.includes(:teacher, :student, user_roles: [:role, :unity]).ordered

      users.each do |user|
        csv << [
          user.first_name,
          user.last_name,
          user.email,
          user.login,
          user.phone,
          user.cpf,
          I18n.t("enumerations.user_status.#{user.status}"),
          user.student,
          user.teacher,
          user.user_roles.map { |user_role| [user_role&.role&.name, user_role&.unity&.name].compact },
          user.expiration_date&.strftime("%d/%m/%Y")
        ]
      end
    end
  end

  def self.find_for_authentication(conditions)
    credential = conditions.fetch(:credentials)
    if CPF.valid?(credential)
      where(%Q((
        users.cpf != '' AND REGEXP_REPLACE(users.cpf, '[^\\d]+', '', 'g') = REGEXP_REPLACE(:credential, '[^\\d]+', '', 'g')
      )), credential: credential).first
    else
      where(%Q(users.login = :credential OR users.email = :credential), credential: credential).first
    end
  end

  def first_access?
    email&.include?('ambiente.portabilis.com.br') &&
      created_at.to_date >= last_password_change.to_date
  end

  def expired?
    return false if admin? || new_record?

    days_to_expire = GeneralConfiguration.current.days_to_disable_access || 0
    return false if expiration_date.blank? && days_to_expire.zero?

    unless days_to_expire.zero?
      days_without_access = (Date.current - last_activity_at.to_date).to_i
      if days_without_access >= days_to_expire
        update_status(UserStatus::PENDING)
        return true
      end
    end

    return false if expiration_date.nil? || expiration_date.blank?

    if Date.current >= expiration_date
      update_status(UserStatus::PENDING)
      update_column :expiration_date, nil
      true
    else
      false
    end
  end

  def update_status(status)
    update_column :status, status
  end

  def status_changed
    return if self.errors.any? || new_record? || (status_was == status)

    if status == UserStatus::ACTIVE
      update_last_activity_at
      unlock_access!
    else
      update_column :expiration_date, nil
    end
  end

  def valid_password
    return if new_record?
    return if encrypted_password.blank?
    return if encrypted_password_was == encrypted_password

    update_last_password_change
  end

  def update_last_password_change
    update_column :last_password_change, Date.current
  end

  def update_last_activity_at
    self.last_activity_at = Date.current
  end

  def can_show?(feature)
    if feature == "general_configurations"
      return admin?
    end
    return true if admin?
    return unless current_user_role

    current_user_role.role.can_show?(feature)
  end

  def can_change?(feature)
    if feature == "general_configurations"
      return admin?
    end
    return true if admin?
    return unless current_user_role

    current_user_role.role.can_change?(feature)
  end

  def update_tracked_fields!(request)
    logins.create!(
      sign_in_ip: request.remote_ip
    )

    super
  end

  def active_for_authentication?
    super && active? && !expired?
  end

  def logged_as
    login.presence || email
  end

  def name
    "#{first_name} #{last_name}".strip
  end

  def activation_sent!
    update_column :activation_sent_at, DateTime.current
  end

  def activation_sent?
    self.activation_sent_at.present?
  end

  def raw_phone
    phone.gsub(/[^\d]/, '')
  end

  def student_api_codes
    codes = [students.pluck(:api_code)]
    codes.push(student.api_code) if student
    codes.flatten
  end

  def roles
    user_roles.includes(:role, :unity).map(&:role)
  end

  def set_current_user_role!(user_role_id = nil)
    return false unless user_role_id.blank? || user_roles.exists?(id: user_role_id)

    default_user_role_id = user_roles.first&.id if user_role_id.blank?

    clear_allocation

    update_attribute(:current_user_role_id, user_role_id || default_user_role_id)
  end

  def read_notifications!
    system_notification_targets.read!
  end

  def to_s
    return email unless name.strip.present?

    name
  end

  def navigation_display
    if first_name.present? && last_name.present?
      "#{first_name}.#{last_name.split(' ').last}"
    elsif first_name.present?
      "#{first_name}"
    elsif login.present?
      "#{login}"
    else
      ''
    end
  end

  def email=(value)
    write_attribute(:email, value) if value.present?
  end

  def cpf=(value)
    write_attribute(:cpf, value) if value.present?
  end

  def current_unity
    @current_unity ||= Unity.find_by_id(current_unity_id) || current_user_role.try(:unity)
  end

  def current_classroom
    return unless current_classroom_id

    @current_classroom ||= begin
      classroom = Classroom.find_by(id: current_classroom_id)
      update(current_classroom_id: nil) if classroom.nil?

      classroom
    end
  end

  def current_teacher
    @current_teacher ||=
      begin
        return teacher if teacher?

        assumed_teacher
      end
  end

  def current_teacher_id
    current_teacher.try(:id)
  end

  def has_administrator_access_level?
    access_levels.include?(AccessLevel::ADMINISTRATOR)
  end

  def can_receive_news_related_daily_teacher?
    (access_levels & [AccessLevel::ADMINISTRATOR, AccessLevel::EMPLOYEE, AccessLevel::TEACHER]).any?
  end

  def can_receive_news_related_tools_for_parents?
    permissions = [AccessLevel::ADMINISTRATOR, AccessLevel::EMPLOYEE, AccessLevel::PARENT, AccessLevel::STUDENT]

    (access_levels & permissions).any?
  end

  def can_receive_news_related_all_matters?
    (access_levels & [AccessLevel::ADMINISTRATOR, AccessLevel::EMPLOYEE]).any?
  end

  def current_role_is_admin_or_employee_or_teacher?
    current_access_level.in? [AccessLevel::ADMINISTRATOR, AccessLevel::EMPLOYEE, AccessLevel::TEACHER]
  end

  def current_role_is_admin_or_employee?
    current_access_level.in? [AccessLevel::ADMINISTRATOR, AccessLevel::EMPLOYEE]
  end

  def current_role_is_parent?
    current_access_level == AccessLevel::PARENT
  end

  def has_admin_or_employee_or_teacher_access_level?
    can_receive_news_related_daily_teacher?
  end

  def clear_allocation
    self.current_school_year = nil
    self.current_user_role_id = nil
    self.current_classroom_id = nil
    self.current_discipline_id = nil
    self.current_unity_id = nil
    self.assumed_teacher_id = nil

    save(validate: false)
  end

  def has_to_validate_receive_news_fields?
    has_to_validate_receive_news_fields == true || has_to_validate_receive_news_fields == 'true'
  end

  def current_access_level
    return unless current_user_role
    current_user_role.role.access_level
  end

  def administrator?
    return false unless current_user_role
    current_user_role.role.access_level == AccessLevel::ADMINISTRATOR
  end

  def employee?
    return false unless current_user_role
    current_user_role.role.access_level == AccessLevel::EMPLOYEE
  end

  def teacher?
    return false unless current_user_role
    current_user_role.role.access_level == AccessLevel::TEACHER
  end

  def parent_can_change_profile?
    return false unless current_role_is_parent?

    has_admin_or_employee_or_teacher_access_level?
  end

  def cpf_as_integer
    cpf.gsub(/[^\d]/, '')
  end

  def access_levels
    @access_levels ||= roles.map(&:access_level).uniq
  end

  protected

  def teacher_access_level?
    access_levels.include? AccessLevel::TEACHER
  end

  def email_required?
    false
  end

  def presence_of_email_or_cpf
    return if errors[:email].any? || errors[:cpf].any?

    if email.blank? && cpf.blank?
      errors.add(:base, :must_inform_email_or_cpf)
    end
  end

  def verify_receive_news_fields
    return true unless persisted?
    self.receive_news_related_daily_teacher = false unless can_receive_news_related_daily_teacher?
    self.receive_news_related_tools_for_parents = false unless can_receive_news_related_tools_for_parents?
    self.receive_news_related_all_matters = false unless can_receive_news_related_all_matters?

    if !receive_news?
      self.receive_news_related_daily_teacher = false
      self.receive_news_related_tools_for_parents = false
      self.receive_news_related_all_matters = false
    end
    true
  end

  def validate_receive_news_fields
    if receive_news? && !(
        receive_news_related_daily_teacher? ||
         receive_news_related_tools_for_parents? || receive_news_related_all_matters?)
      errors.add(:receive_news, :must_fill_receive_news_options)
    end
  end

  def can_not_be_a_cpf
    return unless CPF.valid?(login)

    errors.add(:login, :can_not_be_a_cpf)
  end

  def can_not_be_an_email
    return unless login =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i

    errors.add(:login, :can_not_be_an_email)
  end

  def only_student?
    student? && roles.count == 1
  end

  def update_fullname_tokens
    return unless first_name_changed? || last_name_changed?

    User.where(id: id).update_all("fullname_tokens = to_tsvector('portuguese', fullname)")
  end

  def email_reserved_for_student
    return unless email

    student_api_code, student_domain = email.split('@')

    return if student_domain != 'ambiente.portabilis.com.br'

    if persisted? && Student.joins('LEFT JOIN users ON users.student_id = students.id')
                            .where(users: { student_id: nil })
                            .where(api_code: student_api_code)
                            .any?
      errors.add(:email, :invalid_email)
    end
  end

  def remove_spaces_from_name
    write_attribute(:first_name, first_name.squish) if first_name.present?
    write_attribute(:last_name, last_name.squish) if last_name.present?
  end

  def validate_student_presence
    errors.add(:student, :blank) if student.blank?
  end
end
