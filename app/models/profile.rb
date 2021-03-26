class Profile < ActiveRecord::Base
  acts_as_copy_target

  audited

  has_enumeration_for :role, :with => ProfileRoles

  validates :role, presence: true, uniqueness: true

  def self.permissions_list
    [
      'manage_profiles',
      'manage_users',
    ]
  end

  def self.all_audits
    Audited::Audit.where(auditable_type: 'Profile').reorder("id DESC")
  end
end
