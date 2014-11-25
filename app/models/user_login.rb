class UserLogin < Portabilis::Model
  belongs_to :user

  validates :user, :sign_in_ip, presence: true
end
