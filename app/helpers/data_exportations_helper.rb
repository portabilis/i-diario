module DataExportationsHelper
  def formatted_backup_link(backup)
    return unless backup.created_at.present?

    link_to I18n.l(backup.created_at), backup.backup_file_url
  end

  def backup_status_message(backup)
    return formatted_backup_link(backup) if backup.completed?
    return "Erro: #{backup.error_message}" if backup.error?
  end

  def backup_button_or_status(form, backup, backup_type)
    return exporting_button if backup.started?

    form.submit 'Exportar', name: "backup_type[#{backup_type}]", class: 'btn bg-color-red txt-color-white'
  end

  def exporting_button
    link_to '#', class: 'btn bg-color-red txt-color-white' do
      content_tag(:i, '', class: 'fa fa-cog fa-spin') + ' Exportando...'
    end
  end
end
