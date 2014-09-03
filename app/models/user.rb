class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :lockable

  attr_accessor :credentials

  has_many :logins, class_name: "UserLogin", dependent: :destroy

  validates :phone, mask: { with: "(99) 9999-9999", message: :incorrect_format }, allow_blank: true

  validates :cpf, mask: { with: "999.999.999-99", message: :incorrect_format }, allow_blank: true
  validates :email, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i }, presence: true

  def self.find_for_authentication(conditions)
    credential = conditions.fetch(:credentials)

    where(%Q(
      users.login = :credential OR
      users.email = :credential OR
      REGEXP_REPLACE(users.cpf, '[^\\d]+', '', 'g') = REGEXP_REPLACE(:credential, '[^\\d]+', '', 'g') OR
      REGEXP_REPLACE(users.phone, '[^\\d]+', '', 'g') = REGEXP_REPLACE(:credential, '[^\\d]+', '', 'g')
    ), credential: credential).first
  end

  def update_tracked_fields!(request)
    logins.create!(
      sign_in_ip: request.remote_ip
    )

    super
  end
end
