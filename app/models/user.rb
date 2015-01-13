class User < ActiveRecord::Base
  acts_as_copy_target

  audited allow_mass_assignment: true,
    only: [:email, :first_name, :last_name, :phone, :cpf, :login,
           :authorize_email_and_sms, :student_id, :status]
  has_associated_audits

  include Audit

  devise :database_authenticatable, :recoverable, :rememberable,
    :trackable, :validatable, :lockable

  attr_accessor :credentials

  has_enumeration_for :status, with: UserStatus, create_helpers: true
  has_enumeration_for :kind, with: UserKind, create_helpers: true

  belongs_to :student
  belongs_to :role

  has_many :logins, class_name: "UserLogin", dependent: :destroy
  has_many :syncronizations, class_name: "IeducarApiSyncronization", foreign_key: :author_id
  has_many :***REMOVED***, dependent: :destroy
  has_many :requested_***REMOVED***, class_name: "***REMOVED***Request",
    foreign_key: :requestor_id
  has_many :responsible_***REMOVED***, class_name: "***REMOVED***",
    foreign_key: :responsible_id
  has_many :responsible_***REMOVED***, class_name: "***REMOVED***",
    foreign_key: :responsible_id
  has_many :responsible_requested_***REMOVED***, class_name: "***REMOVED***RequestAuthorization",
    foreign_key: :responsible_id
  has_many :***REMOVED***s, foreign_key: :author_id

  has_and_belongs_to_many :students

  has_many :***REMOVED***
  has_many :authorization_***REMOVED***
  has_many :***REMOVED***

  validates :cpf, mask: { with: "999.999.999-99", message: :incorrect_format }, allow_blank: true
  validates :phone, format: { with: /\A\([0-9]{2}\)\ [0-9]{8,9}\z/i }, allow_blank: true
  validates :email, email: true, presence: true
  validates :student, presence: true, if: :actived_student?

  scope :ordered, -> { order(arel_table[:first_name].asc) }
  scope :authorized_email_and_sms, -> { where(arel_table[:authorize_email_and_sms].eq(true)) }
  scope :with_phone, -> { where(arel_table[:phone].not_eq(nil)) }

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
    return true if admin?
    return unless role

    role.can_show?(feature)
  end

  def can_change?(feature)
    return true if admin?
    return unless role

    role.can_change?(feature)
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

  def actived!
    update_column :actived_at, DateTime.current
  end

  def raw_phone
    phone.gsub(/[^\d]/, '')
  end

  def to_s
    return email unless first_name.present?

    name
  end

  protected

  def actived_student?
    actived? && student?
  end
end
