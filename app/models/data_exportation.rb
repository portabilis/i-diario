class DataExportation < ApplicationRecord
  has_enumeration_for :backup_type, with: BackupTypes, create_helpers: true
  has_enumeration_for :backup_status, with: BackupStatus, create_helpers: true

  mount_uploader :backup_file, BackupFileUploader

  def self.last_by_type(type)
    self.where(backup_type: type).order(:created_at).last.presence || new
  end

  def mark_with_error!(message)
    update(
      backup_status: BackupStatus::ERROR,
      error_message: message
    )
  end
end
