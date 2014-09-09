class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :lockable

  attr_accessor :credentials

  has_many :logins, class_name: "UserLogin", dependent: :destroy

  validates :cpf, mask: { with: "999.999.999-99", message: :incorrect_format }, allow_blank: true
  validates :phone, format: { with: /\A\([0-9]{2}\)\ [0-9]{4,5}-[0-9]{4}\z/i }, allow_blank: true
  validates :email, email: true, presence: true

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
end
