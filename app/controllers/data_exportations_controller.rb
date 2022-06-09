class DataExportationsController < ApplicationController
  def index
    @last_full_system_backup = DataExportation.last_by_type(BackupTypes::FULL_SYSTEM_BACKUP)
    @last_school_calendar_backup = DataExportation.last_by_type(BackupTypes::SCHOOL_CALENDAR_BACKUP)
    @last_unique_school_days_backup = DataExportation.last_by_type(BackupTypes::UNIQUE_SCHOOL_DAYS_BACKUP)


    authorize DataExportation
  end

  def create
    backup_type = params[:backup_type].keys[0]
    data_exportation = DataExportation.new
    data_exportation.backup_type = backup_type
    data_exportation.backup_status = BackupStatus::STARTED
    data_exportation.save!

    BackupFileWorker.perform_async(current_entity.id, data_exportation.id)

    redirect_to data_exportations_path, notice: t('flash.backup_files.create.notice')
  end
end
