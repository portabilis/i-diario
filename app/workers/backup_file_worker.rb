class BackupFileWorker
  include Sidekiq::Worker

  def perform(entity_id, data_exportation_id)
    entity = Entity.find(entity_id)

    entity.using_connection do
      begin
        data_exportation = DataExportation.find(data_exportation_id)

        backup = BackupFile.process_by_type!(data_exportation.backup_type)

        data_exportation.backup_file = backup
        data_exportation.backup_status = BackupStatus::COMPLETED
        data_exportation.save!

        backup.close
        backup.unlink
      rescue StandardError => error
        data_exportation.mark_with_error!(error.message)
      end
    end
  end
end
