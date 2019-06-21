class BackupFileWorker
  include Sidekiq::Worker
  include EntityWorker

  def perform_in_entity
    configuration = GeneralConfiguration.current

    begin
      backup = BackupFile.process!

      configuration.backup_file = backup
      configuration.backup_status = ApiSynchronizationStatus::COMPLETED
      configuration.save!

      backup.close
      backup.unlink
    rescue Exception => e
      configuration.mark_with_error!(e.message)
    end
  end
end
