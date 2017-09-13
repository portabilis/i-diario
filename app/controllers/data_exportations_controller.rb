class DataExportationsController < ApplicationController
  def index
    @data_exportation = DataExportation.new.current

    authorize @data_exportation
  end

  def create
    configuration = DataExportation.new.current
    configuration.backup_file = nil
    configuration.backup_status = ApiSynchronizationStatus::STARTED
    configuration.save!

    @backup_file = BackupFileWorker.perform_async(current_entity.id)

    redirect_to data_exportations_path, notice: t('flash.backup_files.create.notice')
  end
end
