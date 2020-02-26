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

  with_options presence: true, if: :notify_consecutive_or_alternate_absences do
    validates :max_consecutive_absence_days
    validates :max_alternate_absence_days
    validates :days_to_consider_alternate_absences
  end

  belongs_to :employees_default_role, class_name: 'Role', foreign_key: 'employees_default_role_id'

  def self.current
    self.first.presence || new
  end

  def allows_after_sales_relationship?
    allows_after_sales_relationship == AfterSaleRelationshipOptions::ALLOWS
  end

  def mark_with_error!(message)
    update_columns(
      backup_status: ApiSynchronizationStatus::ERROR,
      error_message: message
    )
  end
end
