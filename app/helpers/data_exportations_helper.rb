module DataExportationsHelper
  def formatted_backup_link(backup)
    return unless backup.created_at.present?

    link_to I18n.l(backup.created_at), backup.backup_file_url
  end

  def backup_status_message(backup)
    return formatted_backup_link(backup) if backup.completed?
    return "Erro: #{backup.error_message}" if backup.error?
  end
end
