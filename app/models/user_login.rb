class UserLogin < ActiveRecord::Base
  belongs_to :user

  validates :user, :sign_in_ip, presence: true
end
