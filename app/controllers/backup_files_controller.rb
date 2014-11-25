class BackupFilesController < ApplicationController
  def create
    configuration = GeneralConfiguration.current
    configuration.backup_file = nil
    configuration.backup_status = ApiSyncronizationStatus::STARTED
    configuration.save!

    @backup_file = BackupFileWorker.perform_async(current_entity.id)

    redirect_to edit_general_configurations_path, notice: t('flash.backup_files.create.notice')
  end
end
