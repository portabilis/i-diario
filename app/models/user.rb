class User < ActiveRecord::Base
  acts_as_copy_target

  audited allow_mass_assignment: true,
    only: [:email, :first_name, :last_name, :phone, :cpf, :login,
           :authorize_email_and_sms, :student_id, :status, :encrypted_password]
  has_associated_audits

  include Audit
  include Filterable

  devise :database_authenticatable, :recoverable, :rememberable,
    :trackable, :validatable, :lockable

  attr_accessor :credentials, :has_to_validate_receive_news_fields

  has_enumeration_for :kind, with: RoleKind, create_helpers: true
  has_enumeration_for :status, with: UserStatus, create_helpers: true

  before_destroy :ensure_has_no_audits
  before_validation :verify_receive_news_fields

  belongs_to :student
  belongs_to :teacher
  belongs_to :current_user_role, class_name: 'UserRole'

  has_many :logins, class_name: "UserLogin", dependent: :destroy
  has_many :synchronizations, class_name: "IeducarApiSynchronization", foreign_key: :author_id, dependent: :restrict_with_error
  has_many :***REMOVED***, dependent: :destroy
  has_many :requested_***REMOVED***, class_name: "***REMOVED***Request",
    foreign_key: :requestor_id, dependent: :restrict_with_error
  has_many :responsible_***REMOVED***, class_name: "***REMOVED***",
    foreign_key: :responsible_id, dependent: :restrict_with_error
  has_many :responsible_***REMOVED***, class_name: "***REMOVED***",
    foreign_key: :responsible_id, dependent: :restrict_with_error
  has_many :responsible_requested_***REMOVED***, class_name: "***REMOVED***RequestAuthorization",
    foreign_key: :responsible_id, dependent: :restrict_with_error
  has_many :***REMOVED***s, foreign_key: :author_id, dependent: :restrict_with_error
  has_many :system_notification_targets, dependent: :destroy
  has_many :message_targets, dependent: :destroy
  has_many :messages, through: :message_targets, foreign_key: :author_id, dependent: :destroy
  has_many :sent_messages, class_name: "Message", foreign_key: :author_id, dependent: :destroy
  has_many :ieducar_api_exam_postings, class_name: "IeducarApiExamPosting", foreign_key: :author_id, dependent: :restrict_with_error

  has_and_belongs_to_many :students, dependent: :restrict_with_error

  has_many :***REMOVED***, dependent: :restrict_with_error
  has_many :authorization_***REMOVED***, dependent: :restrict_with_error
  has_many :***REMOVED***, dependent: :restrict_with_error
  has_many :user_roles, -> { includes(:role) }, dependent: :destroy

  accepts_nested_attributes_for :user_roles, reject_if: :all_blank, allow_destroy: true

  validates :cpf, mask: { with: "999.999.999-99", message: :incorrect_format }, allow_blank: true
  validates :phone, format: { with: /\A\([0-9]{2}\)\ [0-9]{8,9}\z/i }, allow_blank: true
  validates :email, email: true, allow_blank: true
  validates :password, length: { minimum: 8 }, allow_blank: true

  validates_associated :user_roles

  validate :uniqueness_of_student_parent_role
  validate :presence_of_email_or_cpf
  validate :validate_receive_news_fields, if: :has_to_validate_receive_news_fields?

  scope :ordered, -> { order(arel_table[:first_name].asc) }
  scope :email_ordered, -> { order(email: :asc)  }
  scope :authorized_email_and_sms, -> { where(arel_table[:authorize_email_and_sms].eq(true)) }
  scope :with_phone, -> { where(arel_table[:phone].not_eq(nil)).where(arel_table[:phone].not_eq("")) }
  scope :admin, -> { where(arel_table[:admin].eq(true)) }
  scope :by_unity_id, lambda { |unity_id| joins(:user_roles).where(user_roles: { unity_id: unity_id }) }

  #search scopes
  scope :full_name, lambda { |full_name| where("first_name || ' ' || last_name ILIKE ?", "%#{full_name}%")}
  scope :email, lambda { |email| where("email ILIKE ?", "%#{email}%")}
  scope :login, lambda { |login| where("login ILIKE ?", "%#{login}%")}
  scope :status, lambda { |status| where status: status }

  def self.to_csv
    attributes = ["Nome", "Sobrenome", "E-mail", "Nome de usuário", "Celular"]

    CSV.generate(headers: true) do |csv|
      csv << attributes

      all.each do |user|
        csv << [user.first_name, user.last_name, user.email, user.login, user.phone]
      end
    end
  end

  def self.find_for_authentication(conditions)
    credential = conditions.fetch(:credentials)

    where(%Q(
      users.login = :credential OR
      users.email = :credential OR
      (
        users.cpf != '' AND
        REGEXP_REPLACE(users.cpf, '[^\\d]+', '', 'g') = REGEXP_REPLACE(:credential, '[^\\d]+', '', 'g')
      ) OR
      (
        users.phone != '' AND
        REGEXP_REPLACE(users.phone, '[^\\d]+', '', 'g') = REGEXP_REPLACE(:credential, '[^\\d]+', '', 'g')
      )
    ), credential: credential).first
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
    super && actived?
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

  def set_current_user_role!(user_role_id)
    return false unless user_roles.exists?(id: user_role_id)

    update_column(:current_user_role_id, user_role_id)
  end

  def system_***REMOVED***
    SystemNotification.where(id: system_notification_targets.pluck(:system_notification_id))
  end

  def unread_***REMOVED***
    @unread_***REMOVED*** ||= system_***REMOVED***.
      not_in(system_notification_targets.read.pluck(:system_notification_id)).
      ordered
  end

  def count_unread_messages
    message_targets.unread.active.count
  end

  def read_***REMOVED***!
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
    @current_unity ||= current_user_role.try(:unity) || Unity.find_by_id(current_unity_id)
  end

  def current_classroom
    return unless current_classroom_id
    @current_classroom ||= Classroom.find(current_classroom_id)
  end

  def current_discipline
    return unless current_discipline_id
    @current_discipline ||= Discipline.find(current_discipline_id)
  end

  def current_teacher
    if current_user_role.try(:role_teacher?)
      teacher
    elsif assumed_teacher_id
      Teacher.find_by_id(assumed_teacher_id)
    end
  end


  def can_receive_news_related_daily_teacher?
    roles.map(&:access_level).uniq.any?{|access_level| ["administrator", "employee", "teacher"].include? access_level}
  end

  def can_receive_news_related_***REMOVED***?
    roles.map(&:access_level).uniq.any?{|access_level| ["administrator", "employee"].include? access_level}
  end

  def can_receive_news_related_tools_for_parents?
    roles.map(&:access_level).uniq.any?{|access_level| ["administrator", "employee", "parent", "student"].include? access_level}
  end

  def can_receive_news_related_all_matters?
    roles.map(&:access_level).uniq.any?{|access_level| ["administrator", "employee"].include? access_level}
  end

  def update_rd_lead
    return unless GeneralConfiguration.current.allows_after_sales_relationship?
    return unless Rails.env.production?
    rdstation_client = RDStation::Client.new('***REMOVED***', '***REMOVED***', 'Usuário no produto Educar+')

    response = rdstation_client.create_lead({
      :"email" => email,
      :"Cargo" => rd_access_level,
      :"Nome" => name,
      :"Telefone fixo" => phone,
      :"Empresa" => EntityConfiguration.current.entity_name,
      :"Recebe informações do Educar plus?" => rd_matters,
      :identificador => 'Usuário no produto Educar+'
    })
  end

  def clear_allocation
    update_attribute(:current_user_role_id, nil)
    update_attribute(:current_classroom_id, nil)
    update_attribute(:current_discipline_id, nil)
    update_attribute(:current_unity_id, nil)
    update_attribute(:assumed_teacher_id, nil)
  end

  def has_to_validate_receive_news_fields?
    has_to_validate_receive_news_fields == true || has_to_validate_receive_news_fields == 'true'
  end

  protected

  def rd_matters
    options = []
    options << "Diário do professor" if receive_news_related_daily_teacher?
    options << "***REMOVED*** e alimentação escolar" if receive_news_related_***REMOVED***?
    options << "Pais e alunos" if receive_news_related_tools_for_parents?
    options << "Todos os assuntos relacionados ao Educar+" if receive_news_related_all_matters?
    options << "Nenhum" if options.blank?
    options
  end

  def rd_access_level
    access_levels = roles.map(&:access_level).uniq
    return "administrador" if access_levels.include? "administrator"
    return "servidor" if access_levels.include? "employee"
    return "professor" if access_levels.include? "teacher"
    return "pais" if access_levels.include? "parent"
    return "alunos" if access_levels.include? "student"
  end

  def email_required?
    false
  end

  def uniqueness_of_student_parent_role
    return if user_roles.blank?

    parent_roles = []
    student_roles = []

    user_roles.reject(&:marked_for_destruction?).each do |user_role|
      _role = Role.find(user_role.role_id)

      next if _role.teacher?

      case _role.access_level.to_s
      when AccessLevel::PARENT
        if parent_roles.include?(_role)
          errors.add(:user_roles, :invalid)
          user_role.errors.add(:role_id, :parent_role_taken)
        else
          parent_roles.push(_role)
        end
      when AccessLevel::STUDENT
        if student_roles.include?(_role)
          errors.add(:user_roles, :invalid)
          user_role.errors.add(:role_id, :student_role_taken)
        else
          student_roles.push(_role)
        end
      end
    end
  end

  def presence_of_email_or_cpf
    return if errors[:email].any? || errors[:cpf].any?

    if email.blank? && cpf.blank?
      errors.add(:base, :must_inform_email_or_cpf)
    end
  end

  def ensure_has_no_audits
    user_id = self.id
    query = "SELECT COUNT(*) FROM audits WHERE audits.user_id = '#{user_id}'"
    audits_count = ActiveRecord::Base.connection.execute(query).first.fetch("count").to_i
    if audits_count > 0
      errors.add(:base, "")
      false
    end
  end

  def verify_receive_news_fields
    return true unless persisted?
    self.receive_news_related_daily_teacher = false unless can_receive_news_related_daily_teacher?
    self.receive_news_related_***REMOVED*** = false unless can_receive_news_related_***REMOVED***?
    self.receive_news_related_tools_for_parents = false unless can_receive_news_related_tools_for_parents?
    self.receive_news_related_all_matters = false unless can_receive_news_related_all_matters?

    if !receive_news?
      self.receive_news_related_daily_teacher = false
      self.receive_news_related_***REMOVED*** = false
      self.receive_news_related_tools_for_parents = false
      self.receive_news_related_all_matters = false
    end
    true
  end

  def validate_receive_news_fields
    if receive_news? && !(
        receive_news_related_daily_teacher? || receive_news_related_***REMOVED***? ||
         receive_news_related_tools_for_parents? || receive_news_related_all_matters?)
      errors.add(:receive_news, :must_fill_receive_news_options)
    end
  end
end
