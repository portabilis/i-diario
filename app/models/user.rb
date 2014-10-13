class User < ActiveRecord::Base
  devise :database_authenticatable, :recoverable, :rememberable,
    :trackable, :validatable, :lockable

  attr_accessor :credentials

  has_many :logins, class_name: "UserLogin", dependent: :destroy
  has_many :syncronizations, class_name: "IeducarApiSyncronization", foreign_key: :author_id
  has_many :***REMOVED***, dependent: :destroy
  has_many :requested_***REMOVED***, class_name: "***REMOVED***Request", foreign_key: :requestor_id
  has_many :responsible_requested_***REMOVED***, class_name: "***REMOVED***RequestAuthorization",
    foreign_key: :responsible_id

  has_and_belongs_to_many :students

  validates :cpf, mask: { with: "999.999.999-99", message: :incorrect_format }, allow_blank: true
  validates :phone, format: { with: /\A\([0-9]{2}\)\ [0-9]{4,5}-[0-9]{4}\z/i }, allow_blank: true
  validates :email, email: true, presence: true

  scope :ordered, -> { order(arel_table[:first_name].asc) }

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

  def update_tracked_fields!(request)
    logins.create!(
      sign_in_ip: request.remote_ip
    )

    super
  end

  def to_s
    "#{first_name} #{last_name}"
  end
end
