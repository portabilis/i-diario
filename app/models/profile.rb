class Profile < ActiveRecord::Base
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
    Audited::Adapters::ActiveRecord::Audit.where(auditable_type: 'Profile').reorder("id DESC")
  end
end
