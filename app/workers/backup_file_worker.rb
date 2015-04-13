class BackupFileWorker
  include Sidekiq::Worker

  def perform(entity_id)
    entity = Entity.find(entity_id)

    entity.using_connection do
      configuration = GeneralConfiguration.current

      begin
        backup = BackupFile.process!

        configuration.backup_file = backup
        configuration.backup_status = ApiSyncronizationStatus::COMPLETED
        configuration.save!

        backup.close
        backup.unlink
      rescue Exception => e
        configuration.mark_with_error!(e.message)
      end
    end
  end
end
