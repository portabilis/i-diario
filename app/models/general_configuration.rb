class GeneralConfiguration < ActiveRecord::Base
  acts_as_copy_target

  audited

  include Audit

  has_enumeration_for :backup_status, with: ApiSyncronizationStatus, create_helpers: true
  has_enumeration_for :security_level, with: SecurityLevels

  mount_uploader :backup_file, BackupFileUploader

  validates :security_level, presence: true

  def self.current
    self.first.presence || new
  end
end
