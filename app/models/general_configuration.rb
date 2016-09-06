class GeneralConfiguration < ActiveRecord::Base
  acts_as_copy_target

  audited

  include Audit

  has_enumeration_for :backup_status, with: ApiSynchronizationStatus, create_helpers: true
  has_enumeration_for :security_level, with: SecurityLevels
  has_enumeration_for :allows_after_sales_relationship, with: AfterSaleRelationshipOptions

  mount_uploader :backup_file, BackupFileUploader

  validates :security_level, presence: true
  validates :allows_after_sales_relationship, presence: true

  belongs_to :students_default_role, class_name: 'Role', foreign_key: 'students_default_role_id'
  belongs_to :employees_default_role, class_name: 'Role', foreign_key: 'employees_default_role_id'
  belongs_to :parents_default_role, class_name: 'Role', foreign_key: 'parents_default_role_id'

  def self.current
    self.first.presence || new
  end

  def mark_with_error!(message)
    update_columns(
      backup_status: ApiSynchronizationStatus::ERROR,
      error_message: message
    )
  end
end
