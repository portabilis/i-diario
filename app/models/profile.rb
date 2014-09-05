class Profile < ActiveRecord::Base
  has_enumeration_for :role, :with => ProfileRoles

  validates :role, presence: true, uniqueness: true

  def self.permissions_list
    [
      'manage_profiles',
      'manage_users',
    ]
  end
end
