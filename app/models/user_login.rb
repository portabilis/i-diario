class UserLogin < ApplicationRecord
  acts_as_copy_target

  belongs_to :user

  validates :user, :sign_in_ip, presence: true
end
